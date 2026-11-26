import Carbon.HIToolbox
import Observation
import SwiftUI

/// Clipboard history: records copied text and opens a quick-paste panel on ⌘⇧V.
final class ClipboardPlugin: Plugin {
    static let manifest = PluginManifest(
        id: "clipboard",
        name: "Clipboard History",
        icon: "doc.on.clipboard",
        summary: "Keep a searchable history of copied text and paste it from the keyboard."
    )

    private let settings: ClipboardSettings
    private let store: ClipboardStore
    private let panel: ClipboardPanel
    private var monitor: ClipboardMonitor?

    init(context: PluginContext) {
        let store = ClipboardStore(fileURL: context.dataDirectory.appending(path: "history.json"))
        self.settings = ClipboardSettings(store: context.store)
        self.store = store
        self.panel = ClipboardPanel(store: store)
    }

    var commands: [PluginCommand] {
        [
            PluginCommand(
                id: "clipboard.history",
                title: "Clipboard History",
                icon: "doc.on.clipboard",
                shortcut: HotKey(kVK_ANSI_V, cmdKey | shiftKey)
            ) { [weak self] in self?.panel.toggle() },
        ]
    }

    func activate() throws {
        guard monitor == nil else { return }
        let monitor = ClipboardMonitor { [weak self] text in self?.record(text) }
        monitor.start()
        self.monitor = monitor
    }

    func deactivate() {
        monitor?.stop()
        monitor = nil
        panel.close()
    }

    func makeSettingsView() -> AnyView? {
        AnyView(ClipboardSettingsView(settings: settings, store: store))
    }

    private func record(_ text: String) {
        store.record(text, limit: settings.historyLimit)
    }
}

/// Clipboard preferences, stored in the plugin's own `UserDefaults` namespace.
@Observable
final class ClipboardSettings {
    private let store: PluginStore

    var historyLimit: Int { didSet { store.set(historyLimit, for: "historyLimit") } }

    init(store: PluginStore) {
        self.store = store
        historyLimit = store.value("historyLimit", default: 200)
    }
}

private struct ClipboardSettingsView: View {
    @Bindable var settings: ClipboardSettings
    let store: ClipboardStore

    var body: some View {
        Section("History") {
            Stepper("Keep \(settings.historyLimit) items", value: $settings.historyLimit, in: 20...1000, step: 20)
            Button("Clear History", role: .destructive) { store.clear() }
        }
    }
}
