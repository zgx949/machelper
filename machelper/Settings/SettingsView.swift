import AppKit
import Foundation
import SwiftUI

/// The app's main window, with general preferences before individual plugin settings.
struct SettingsView: View {
    let host: PluginHost
    let appSettings: AppSettings
    let navigation: MainNavigation
    let showSetup: () -> Void
    let hideToMenuBar: () -> Void

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: Binding<String?>(
                    get: { navigation.selection },
                    set: { if let selection = $0 { navigation.selection = selection } }
                )) {
                    Label("General", systemImage: "gearshape")
                        .tag("general")
                    Label("Setup Guide", systemImage: "checklist")
                        .tag("setup")

                    Section("Plugins") {
                        ForEach(host.entries) { entry in
                            PluginRow(entry: entry, isOn: Binding(
                                get: { entry.isEnabled },
                                set: { host.setEnabled($0, for: entry.id) }
                            ))
                            .tag(entry.id)
                        }
                    }
                }
                Divider()
                Button(action: hideToMenuBar) {
                    Label("Hide to Menu Bar", systemImage: "menubar.arrow.up.rectangle")
                        .frame(maxWidth: .infinity)
                }
                    .buttonStyle(.borderless)
                    .padding(12)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 270)
        } detail: {
            if navigation.selection == "setup" {
                SetupView(host: host, finish: hideToMenuBar)
                    .navigationTitle("Setup Guide")
            } else if let entry = host.entries.first(where: { $0.id == navigation.selection }) {
                PluginDetail(host: host, entry: entry, showSetup: showSetup)
                    .navigationTitle(entry.manifest.name)
            } else {
                GeneralSettingsView(host: host, appSettings: appSettings,
                                    showSetup: showSetup, hideToMenuBar: hideToMenuBar)
                    .navigationTitle("General")
            }
        }
        .frame(minWidth: 800, minHeight: 560)
    }
}

private struct GeneralSettingsView: View {
    let host: PluginHost
    let appSettings: AppSettings
    let showSetup: () -> Void
    let hideToMenuBar: () -> Void

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("machelper")
                            .font(.title2.weight(.semibold))
                        Text("Your everyday tools, together in the menu bar.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 6)

                HStack(spacing: 12) {
                    StatusSummary(title: "Running", count: host.entries.filter { $0.state == .running }.count,
                                  color: .green)
                    StatusSummary(title: "Waiting for Permission",
                                  count: host.entries.filter { $0.state == .waitingForPermission }.count,
                                  color: .orange)
                    StatusSummary(title: "Needs Attention", count: failureCount, color: .red)
                }

                if host.hasFailures {
                    Text("A plugin could not start. Select it in the sidebar to see the reason and retry.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Permissions") {
                PermissionsStatusView(host: host, showGuide: showSetup)
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { appSettings.launchAtLoginEnabled },
                    set: { appSettings.setLaunchAtLogin($0) }
                ))
                .help("Start machelper automatically when you sign in to your Mac.")

                if appSettings.loginItemStatus == .requiresApproval {
                    Label("Allow machelper in Login Items to finish enabling automatic launch.",
                          systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                    Button("Open Login Items…") { appSettings.openLoginItemSettings() }
                } else if appSettings.loginItemStatus == .notFound {
                    Text("macOS could not find the login item. Move machelper to Applications and try again.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let error = appSettings.loginItemError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }

                Toggle("Show Main Window at Launch", isOn: Binding(
                    get: { appSettings.showMainWindowAtLaunch },
                    set: { appSettings.showMainWindowAtLaunch = $0 }
                ))
                Text("When turned off, machelper starts in the menu bar. The window still opens if setup needs your attention.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Menu Bar") {
                Label("Closing this window keeps your enabled plugins running.",
                      systemImage: "menubar.rectangle")
                Text("Click the machelper icon at the top of your screen to use tools or reopen this window.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Continue in Menu Bar", action: hideToMenuBar)
                    .buttonStyle(.borderedProminent)
            }

            Section("Installation") {
                LabeledContent("App Location") {
                    Text(Bundle.main.bundlePath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
                if !AppSettings.isInstalledInApplications {
                    Label("Move machelper to Applications before granting permissions or enabling automatic launch.",
                          systemImage: "externaldrive.badge.exclamationmark")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { appSettings.refreshLoginItemStatus() }
    }

    private var failureCount: Int {
        host.entries.filter { if case .failed = $0.state { return true }; return false }.count
    }
}

private struct StatusSummary: View {
    let title: LocalizedStringKey
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(count, format: .number)
                .font(.title2.weight(.semibold))
                .foregroundStyle(count > 0 ? color : .secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}

private struct PluginRow: View {
    let entry: PluginHost.Entry
    let isOn: Binding<Bool>

    var body: some View {
        HStack {
            Image(systemName: entry.manifest.icon)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.manifest.name)
                PluginStatusLabel(state: entry.state)
                    .font(.caption)
            }
            Spacer()
            Toggle(isOn: isOn) { Text(entry.manifest.name) }
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(.vertical, 2)
    }
}

private struct PluginDetail: View {
    let host: PluginHost
    let entry: PluginHost.Entry
    let showSetup: () -> Void

    var body: some View {
        let shortcuts = host.shortcuts(for: entry).filter { $0.command.shortcut != nil }

        Form {
            Section {
                LabeledContent {
                    PluginStatusLabel(state: entry.state)
                } label: {
                    Label(entry.manifest.name, systemImage: entry.manifest.icon)
                        .font(.headline)
                }
                Text(entry.manifest.summary)
                    .foregroundStyle(.secondary)
                if entry.state == .waitingForPermission {
                    Text("Scroll reversal, window tiling and pasting need Accessibility. Enable machelper in System Settings → Privacy & Security → Accessibility.")
                        .font(.callout)
                    Button("Setup Guide…", action: showSetup)
                    Button("Open System Settings…") { Permissions.requestAndOpenAccessibilitySettings() }
                    Button("Check Again") { host.refreshPermissions(retryFailures: true) }
                }
                if case .failed = entry.state {
                    Button("Retry") { host.refreshPermissions(retryFailures: true) }
                }
            }

            if !shortcuts.isEmpty {
                Section("Shortcuts") {
                    ForEach(shortcuts) { ShortcutRow(binding: $0) }
                }
            }

            if let settings = entry.plugin.makeSettingsView() {
                settings
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutRow: View {
    let binding: CommandRegistry.Binding

    var body: some View {
        LabeledContent {
            HStack(spacing: 6) {
                if let conflict = binding.conflict {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .help(conflict == .duplicate
                            ? Text("Used by another command")
                            : Text("Taken by the system or another app"))
                }
                Text(binding.command.shortcut?.displayString ?? "")
                    .monospaced()
                    .foregroundStyle(binding.conflict == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.red))
            }
        } label: {
            CommandLabel(title: binding.command.title, icon: binding.command.icon)
        }
    }
}

struct PluginStatusLabel: View {
    let state: PluginHost.State

    var body: some View {
        switch state {
        case .off:
            Text("Off").foregroundStyle(.secondary)
        case .waitingForPermission:
            Text("Waiting for Accessibility").foregroundStyle(.orange)
        case .running:
            Text("Running").foregroundStyle(.green)
        case .failed(let reason):
            Text("Failed: \(reason)").foregroundStyle(.red)
        }
    }
}
