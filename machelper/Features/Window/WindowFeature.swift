import Carbon.HIToolbox

/// Binds window layouts to global hotkeys (⌃⌥ + arrow / ↩ / C).
final class WindowFeature: Feature {
    private let hotKeys: HotKeyCenter
    private var tokens: [HotKeyCenter.Token] = []

    static let bindings: [(HotKey, WindowLayout)] = {
        let mods = controlKey | optionKey
        return [
            (HotKey(kVK_LeftArrow, mods), .leftHalf),
            (HotKey(kVK_RightArrow, mods), .rightHalf),
            (HotKey(kVK_UpArrow, mods), .topHalf),
            (HotKey(kVK_DownArrow, mods), .bottomHalf),
            (HotKey(kVK_Return, mods), .maximize),
            (HotKey(kVK_ANSI_C, mods), .center),
        ]
    }()

    init(hotKeys: HotKeyCenter = .shared) {
        self.hotKeys = hotKeys
    }

    func start() {
        guard tokens.isEmpty else { return }
        tokens = Self.bindings.compactMap { hotKey, layout in
            hotKeys.register(hotKey) { WindowMover.apply(layout) }
        }
    }

    func stop() {
        tokens.forEach(hotKeys.unregister)
        tokens.removeAll()
    }
}
