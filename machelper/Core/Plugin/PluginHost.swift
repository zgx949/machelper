import Foundation
import Observation

/// Creates every plugin, persists its on/off switch and drives its lifecycle.
///
/// A plugin that is switched on but lacks a permission waits in `.waitingForPermission`;
/// the host polls every 2 s and activates it once granted, so no relaunch is needed.
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

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var permissionTimer: Timer?

    init(plugins: [any Plugin.Type], defaults: UserDefaults = .standard, commands: CommandRegistry = CommandRegistry()) {
        self.defaults = defaults
        self.commands = commands
        self.entries = plugins.map { type in
            Entry(manifest: type.manifest, plugin: type.init(context: PluginContext(id: type.manifest.id, defaults: defaults)))
        }
    }

    var isWaitingForPermission: Bool {
        entries.contains { $0.state == .waitingForPermission }
    }

    func start() {
        for index in entries.indices where isSwitchedOn(entries[index].manifest) {
            activate(at: index)
        }
        if isWaitingForPermission {
            Permissions.requestAccessibility()
        }
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
            if entries[index].state == .waitingForPermission { Permissions.requestAccessibility() }
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
        guard entry.manifest.permissions.allSatisfy(\.isGranted) else {
            entries[index].state = .waitingForPermission
            waitForPermissions()
            return
        }
        do {
            try entry.plugin.activate()
            commands.register(entry.plugin.commands, for: entry.id)
            entries[index].state = .running
        } catch {
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

    private func waitForPermissions() {
        guard permissionTimer == nil else { return }
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.recheckPermissions() }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func recheckPermissions() {
        let waiting = entries.indices.filter { entries[$0].state == .waitingForPermission }
        guard !waiting.isEmpty else { return stopWaiting() }
        for index in waiting where entries[index].manifest.permissions.allSatisfy(\.isGranted) {
            activate(at: index)
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
