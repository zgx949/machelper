import Carbon.HIToolbox

/// Clipboard history: records copied text and opens a quick-paste panel on ⌘⇧V.
final class ClipboardFeature: Feature {
    static let panelHotKey = HotKey(kVK_ANSI_V, cmdKey | shiftKey)

    let store: ClipboardStore
    private let settings: AppSettings
    private let hotKeys: HotKeyCenter
    private let panel: ClipboardPanel
    private var monitor: ClipboardMonitor?
    private var token: HotKeyCenter.Token?

    init(store: ClipboardStore = ClipboardStore(), settings: AppSettings = .shared, hotKeys: HotKeyCenter = .shared) {
        self.store = store
        self.settings = settings
        self.hotKeys = hotKeys
        self.panel = ClipboardPanel(store: store)
    }

    func start() {
        guard monitor == nil else { return }
        let monitor = ClipboardMonitor { [weak self] text in self?.record(text) }
        monitor.start()
        self.monitor = monitor
        token = hotKeys.register(Self.panelHotKey) { [weak self] in self?.panel.toggle() }
    }

    func stop() {
        monitor?.stop()
        monitor = nil
        if let token { hotKeys.unregister(token) }
        token = nil
        panel.close()
    }

    func showPanel() {
        panel.show()
    }

    private func record(_ text: String) {
        guard settings.clipboardEnabled else { return }
        store.record(text, limit: settings.clipboardHistoryLimit)
    }
}
