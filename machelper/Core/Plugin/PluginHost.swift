import Foundation
import Observation

/// Creates every plugin, persists its on/off switch and drives its lifecycle.
///
/// A plugin that is switched on but lacks a permission waits in `.waitingForPermission`;
/// the host polls every second and activates it once granted, so no relaunch is needed.
/// A plugin whose `activate()` throws is marked `.failed` without affecting the others.
@Observable
final class PluginHost {
    enum State: Equatable {
        case off
        case waitingForPermission
        case running
        case failed(String)
    }

    struct Entry: Identifiable {
        let manifest: PluginManifest
        let plugin: any Plugin
        var state: State = .off

        var id: String { manifest.id }
        var isEnabled: Bool { state != .off }
    }

    let commands: CommandRegistry
    private(set) var entries: [Entry]
    private(set) var isAccessibilityGranted = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let permissionGranted: (Permission) -> Bool
    @ObservationIgnored private var permissionTimer: Timer?

    init(plugins: [any Plugin.Type], defaults: UserDefaults = .standard, commands: CommandRegistry = CommandRegistry(),
         permissionGranted: @escaping (Permission) -> Bool = { $0.isGranted }) {
        self.defaults = defaults
        self.commands = commands
        self.permissionGranted = permissionGranted
        self.entries = plugins.map { type in
            Entry(manifest: type.manifest, plugin: type.init(context: PluginContext(id: type.manifest.id, defaults: defaults)))
        }
    }

    var isWaitingForPermission: Bool {
        entries.contains { $0.state == .waitingForPermission }
    }

    var hasFailures: Bool {
        entries.contains { if case .failed = $0.state { return true }; return false }
    }

    func start() {
        isAccessibilityGranted = permissionGranted(.accessibility)
        for index in entries.indices where isSwitchedOn(entries[index].manifest) {
            activate(at: index)
        }
        monitorPermissions()
    }

    func stop() {
        stopWaiting()
        entries.indices.forEach(deactivate(at:))
    }

    func setEnabled(_ enabled: Bool, for id: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        defaults.set(enabled, forKey: Self.enabledKey(id))
        if enabled {
            activate(at: index)
        } else {
            deactivate(at: index)
        }
    }

    /// Live bindings (with conflicts) for a running plugin, otherwise its declared commands.
    func shortcuts(for entry: Entry) -> [CommandRegistry.Binding] {
        commands.bindings[entry.id] ?? entry.plugin.commands.map { CommandRegistry.Binding(command: $0) }
    }

    // MARK: - Lifecycle

    private func activate(at index: Int) {
        let entry = entries[index]
        guard entry.state != .running else { return }
        guard entry.manifest.permissions.allSatisfy(permissionGranted) else {
            entries[index].state = .waitingForPermission
            return
        }
        do {
            try entry.plugin.activate()
            commands.register(entry.plugin.commands, for: entry.id)
            entries[index].state = .running
        } catch {
            // A plugin may have acquired resources before throwing; leave retries a clean slate.
            entry.plugin.deactivate()
            entries[index].state = .failed(error.localizedDescription)
        }
    }

    private func deactivate(at index: Int) {
        if entries[index].state == .running {
            commands.unregister(entries[index].id)
            entries[index].plugin.deactivate()
        }
        entries[index].state = .off
    }

    // MARK: - Permissions

    private func monitorPermissions() {
        guard permissionTimer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshPermissions() }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    /// Also called when returning from System Settings. Failures retry only on user action.
    func refreshPermissions(retryFailures: Bool = false) {
        isAccessibilityGranted = permissionGranted(.accessibility)
        for index in entries.indices where entries[index].isEnabled {
            if !entries[index].manifest.permissions.allSatisfy(permissionGranted) {
                if entries[index].state == .running { deactivate(at: index) }
                entries[index].state = .waitingForPermission
            } else if entries[index].state == .waitingForPermission {
                activate(at: index)
            } else if retryFailures, case .failed = entries[index].state {
                activate(at: index)
            }
        }
    }

    private func stopWaiting() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    // MARK: - Persistence

    private func isSwitchedOn(_ manifest: PluginManifest) -> Bool {
        defaults.object(forKey: Self.enabledKey(manifest.id)) as? Bool ?? manifest.enabledByDefault
    }

    private static func enabledKey(_ id: String) -> String {
        "pluginHost.enabled.\(id)"
    }
}
