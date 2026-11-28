import AppKit
import SwiftUI

/// Shared by General and the guide; system access and plugin health are separate checks.
struct PermissionsStatusView: View {
    let host: PluginHost
    let showGuide: () -> Void
    @State private var checkedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Accessibility", systemImage: "hand.raised.fill")
                    .font(.headline)
                Spacer()
                Label(host.isAccessibilityGranted ? LocalizedStringKey("Granted") : LocalizedStringKey("Not Granted"),
                      systemImage: host.isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(host.isAccessibilityGranted ? .green : .orange)
            }
            Text("Needed for scroll reversal, window layouts, keyboard scrolling and automatic paste. Clipboard history can still record and search without it.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if host.hasFailures {
                Label("Permission is checked separately from feature health. Some features need a retry.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
            HStack {
                if !host.isAccessibilityGranted {
                    Button("Allow Accessibility") { Permissions.requestAndOpenAccessibilitySettings() }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Open System Settings…") { Permissions.openAccessibilitySettings() }
                }
                Button("Check Again") {
                    host.refreshPermissions(retryFailures: true)
                    checkedAt = .now
                }
                Button("Setup Guide…", action: showGuide)
            }
            if let checkedAt {
                HStack(spacing: 4) {
                    Text("Last checked:")
                    Text(checkedAt, style: .time)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A guide that remains available after authorization, including recovery and feature checks.
struct SetupView: View {
    let host: PluginHost
    let finish: () -> Void
    @State private var showTroubleshooting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set Up machelper")
                        .font(.largeTitle.weight(.semibold))
                    Text("A few steps to get your menu bar helper ready.")
                        .foregroundStyle(.secondary)
                }
                step(number: 1, title: "Install", icon: "folder") {
                    Label(AppSettings.isInstalledInApplications ? LocalizedStringKey("Running from Applications") : LocalizedStringKey("Running outside Applications"),
                          systemImage: AppSettings.isInstalledInApplications ? "checkmark.circle.fill" : "info.circle")
                        .foregroundStyle(AppSettings.isInstalledInApplications ? .green : .orange)
                    if !AppSettings.isInstalledInApplications {
                        Text("Grant permissions to the copy in Applications so they stay associated with the app you use. If you are running from the disk image or Downloads, quit and move the app first.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Text(Bundle.main.bundlePath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Button("Show This App in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                    }
                }
                step(number: 2, title: "Accessibility", icon: "hand.raised") {
                    Label(host.isAccessibilityGranted ? LocalizedStringKey("Accessibility is enabled") : LocalizedStringKey("Accessibility is not enabled yet"),
                          systemImage: host.isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(host.isAccessibilityGranted ? .green : .orange)
                    Text("Needed for scroll reversal, window layouts, keyboard scrolling and automatic paste. Clipboard history can still record and search without it.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Open System Settings → Privacy & Security → Accessibility.")
                        Text("Turn on machelper. Authenticate with your Mac password or Touch ID if asked.")
                        Text("Return here. Enabled plugins start automatically after permission is detected.")
                    }
                    .font(.callout)
                    HStack {
                        Button(host.isAccessibilityGranted ? LocalizedStringKey("Open System Settings…") : LocalizedStringKey("Allow Accessibility")) {
                            Permissions.requestAndOpenAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Check Again") { host.refreshPermissions(retryFailures: true) }
                    }
                    DisclosureGroup("Already enabled, or missing from the list?", isExpanded: $showTroubleshooting) {
                        Text("If machelper is missing from the list, use + to add the app in Applications. If an update leaves the switch on but features still fail, remove the old entry with −, add this copy again and enable it.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                }
                step(number: 3, title: "Check Your Features", icon: "checklist") {
                    ForEach(host.entries) { entry in
                        HStack(alignment: .firstTextBaseline) {
                            Label(entry.manifest.name, systemImage: entry.manifest.icon)
                            Spacer()
                            PluginStatusLabel(state: entry.state)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if host.hasFailures {
                        Button("Retry") { host.refreshPermissions(retryFailures: true) }
                    }
                    Text("Open a webpage and scroll with your mouse to check the direction. On a fresh install, mouse reversal is on and trackpad reversal is off. Your existing preferences are preserved.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label("machelper lives in the menu bar at the top of your screen. It does not show a Dock icon.",
                          systemImage: "menubar.rectangle")
                        .foregroundStyle(.secondary)
                    Text("Close this window or continue below. Your enabled features keep running, and the menu bar icon brings you back here.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Continue in Menu Bar", action: finish)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { host.refreshPermissions() }
    }

    private func step<Content: View>(number: Int, title: LocalizedStringKey, icon: String,
                                    @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(verbatim: "\(number)")
                    .font(.headline)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                Label(title, systemImage: icon).font(.headline)
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))
    }
}
