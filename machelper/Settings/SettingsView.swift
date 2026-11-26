import SwiftUI

/// Preferences window: plugin list with on/off switches on the left, the selected plugin on the right.
struct SettingsView: View {
    let host: PluginHost
    @State private var selection: String?

    var body: some View {
        NavigationSplitView {
            List(host.entries, selection: $selection) { entry in
                PluginRow(entry: entry, isOn: Binding(
                    get: { entry.isEnabled },
                    set: { host.setEnabled($0, for: entry.id) }
                ))
            }
            .navigationSplitViewColumnWidth(230)
        } detail: {
            if let entry = host.entries.first(where: { $0.id == selection }) {
                PluginDetail(host: host, entry: entry)
            } else {
                ContentUnavailableView("Select a Plugin", systemImage: "puzzlepiece.extension")
            }
        }
        .frame(width: 700, height: 460)
        .onAppear { selection = selection ?? host.entries.first?.id }
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
                    Button("Open System Settings…") { Permissions.openAccessibilitySettings() }
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
        LabeledContent(binding.command.title) {
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
        }
    }
}

private struct PluginStatusLabel: View {
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
