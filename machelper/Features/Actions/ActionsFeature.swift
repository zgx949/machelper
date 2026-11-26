import Carbon.HIToolbox

/// Keyboard-driven actions that replace former Hammerspoon scripts.
final class ActionsFeature: Feature {
    private let hotKeys: HotKeyCenter
    private var tokens: [HotKeyCenter.Token] = []

    static let bindings: [(HotKey, ScrollAction)] = {
        let mods = controlKey | optionKey
        let big = mods | shiftKey
        return [
            (HotKey(kVK_ANSI_J, mods), .down(lines: 3)),
            (HotKey(kVK_ANSI_K, mods), .up(lines: 3)),
            (HotKey(kVK_ANSI_J, big), .down(lines: 15)),
            (HotKey(kVK_ANSI_K, big), .up(lines: 15)),
        ]
    }()

    init(hotKeys: HotKeyCenter = .shared) {
        self.hotKeys = hotKeys
    }

    func start() {
        guard tokens.isEmpty else { return }
        tokens = Self.bindings.compactMap { hotKey, action in
            hotKeys.register(hotKey) { action.perform() }
        }
    }

    func stop() {
        tokens.forEach(hotKeys.unregister)
        tokens.removeAll()
    }
}
