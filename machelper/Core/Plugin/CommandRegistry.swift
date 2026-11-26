import Observation

/// Registers the global shortcuts of running plugins and records conflicts.
///
/// A shortcut already taken by another command is not registered and is marked `.duplicate`;
/// one the system refuses is marked `.unavailable`. Settings shows both in red.
@Observable
final class CommandRegistry {
    enum Conflict: Equatable {
        case duplicate
        case unavailable
    }

    struct Binding: Identifiable {
        let command: PluginCommand
        var conflict: Conflict?

        var id: String { command.id }
    }

    /// Keyed by plugin id, in the order each plugin declared its commands.
    private(set) var bindings: [String: [Binding]] = [:]

    @ObservationIgnored private let hotKeys: HotKeyCenter
    @ObservationIgnored private var tokens: [String: [HotKeyCenter.Token]] = [:]

    init(hotKeys: HotKeyCenter = .shared) {
        self.hotKeys = hotKeys
    }

    func register(_ commands: [PluginCommand], for pluginID: String) {
        unregister(pluginID)

        var registered: [Binding] = []
        var pluginTokens: [HotKeyCenter.Token] = []
        for command in commands {
            var binding = Binding(command: command)
            if let shortcut = command.shortcut {
                if isTaken(shortcut, besides: registered) {
                    binding.conflict = .duplicate
                } else if let token = hotKeys.register(shortcut, action: command.perform) {
                    pluginTokens.append(token)
                } else {
                    binding.conflict = .unavailable
                }
            }
            registered.append(binding)
        }
        bindings[pluginID] = registered
        tokens[pluginID] = pluginTokens
    }

    func unregister(_ pluginID: String) {
        tokens.removeValue(forKey: pluginID)?.forEach(hotKeys.unregister)
        bindings[pluginID] = nil
    }

    private func isTaken(_ shortcut: HotKey, besides pending: [Binding]) -> Bool {
        (bindings.values.joined() + pending).contains { $0.conflict == nil && $0.command.shortcut == shortcut }
    }
}
