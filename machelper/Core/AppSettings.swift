import Foundation
import Observation

/// User preferences backed by `UserDefaults`. Lives on the main actor; features that run
/// on other threads receive value snapshots instead of reading this directly.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    var reverseMouse: Bool { didSet { defaults.set(reverseMouse, forKey: Key.reverseMouse) } }
    var reverseTrackpad: Bool { didSet { defaults.set(reverseTrackpad, forKey: Key.reverseTrackpad) } }
    var clipboardEnabled: Bool { didSet { defaults.set(clipboardEnabled, forKey: Key.clipboardEnabled) } }
    var clipboardHistoryLimit: Int { didSet { defaults.set(clipboardHistoryLimit, forKey: Key.clipboardHistoryLimit) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.reverseMouse: true,
            Key.reverseTrackpad: false,
            Key.clipboardEnabled: true,
            Key.clipboardHistoryLimit: 200,
        ])
        reverseMouse = defaults.bool(forKey: Key.reverseMouse)
        reverseTrackpad = defaults.bool(forKey: Key.reverseTrackpad)
        clipboardEnabled = defaults.bool(forKey: Key.clipboardEnabled)
        clipboardHistoryLimit = defaults.integer(forKey: Key.clipboardHistoryLimit)
    }

    private enum Key {
        static let reverseMouse = "scroll.reverseMouse"
        static let reverseTrackpad = "scroll.reverseTrackpad"
        static let clipboardEnabled = "clipboard.enabled"
        static let clipboardHistoryLimit = "clipboard.historyLimit"
    }
}
