import SwiftUI

/// Preferences window. Edits `AppSettings` directly; features pick up changes on their own.
struct SettingsView: View {
    let coordinator: AppCoordinator

    var body: some View {
        @Bindable var settings = coordinator.settings

        Form {
            Section("Permissions") {
                if coordinator.isAccessibilityTrusted {
                    Label("Accessibility granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Accessibility required for scrolling, windows and shortcuts", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Button("Open System Settings…") { Permissions.openAccessibilitySettings() }
                }
            }

            Section("Scrolling") {
                Toggle("Reverse mouse", isOn: $settings.reverseMouse)
                Toggle("Reverse trackpad", isOn: $settings.reverseTrackpad)
            }

            Section("Clipboard") {
                Toggle("Record clipboard history", isOn: $settings.clipboardEnabled)
                Stepper("Keep \(settings.clipboardHistoryLimit) items", value: $settings.clipboardHistoryLimit, in: 20...1000, step: 20)
                Button("Clear History", role: .destructive) { coordinator.clipboard.store.clear() }
            }

            Section("Shortcuts") {
                ShortcutRow(title: "Clipboard history", keys: "⌘⇧V")
                ShortcutRow(title: "Left / right half", keys: "⌃⌥← / ⌃⌥→")
                ShortcutRow(title: "Top / bottom half", keys: "⌃⌥↑ / ⌃⌥↓")
                ShortcutRow(title: "Maximize / center", keys: "⌃⌥↩ / ⌃⌥C")
                ShortcutRow(title: "Scroll down / up", keys: "⌃⌥J / ⌃⌥K")
                ShortcutRow(title: "Scroll down / up (page)", keys: "⌃⌥⇧J / ⌃⌥⇧K")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ShortcutRow: View {
    let title: LocalizedStringKey
    let keys: String

    var body: some View {
        LabeledContent(title) {
            Text(keys).monospaced().foregroundStyle(.secondary)
        }
    }
}
