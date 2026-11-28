// Only the system hotkey boundary is replaced. Tests compile the real PluginHost,
// CommandRegistry, plugin types and persistence without registering global shortcuts.
final class HotKeyCenter {
    static let shared = HotKeyCenter()
    typealias Token = UInt32

    func register(_ hotKey: HotKey, action: @escaping () -> Void) -> Token? {
        preconditionFailure("Lifecycle test plugins must not declare global shortcuts")
    }

    func unregister(_ token: Token) {
        preconditionFailure("Lifecycle tests must not own global shortcuts")
    }
}
