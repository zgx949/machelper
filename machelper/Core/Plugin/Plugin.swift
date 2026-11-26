import SwiftUI

/// Static description of a plugin, shown in Settings even while the plugin is off.
struct PluginManifest {
    let id: String
    let name: LocalizedStringKey
    let icon: String
    let summary: LocalizedStringKey
    var permissions: Set<Permission> = []
    var enabledByDefault = true
}

/// A feature that can be switched on and off at runtime.
///
/// Plugins depend only on `Core`, never on each other. `PluginHost` creates every plugin once
/// at launch, calls `activate()` when it is switched on and its permissions are granted, and
/// `deactivate()` when it is switched off. Shortcuts declared in `commands` are registered and
/// removed by the host, so plugins never talk to `HotKeyCenter` themselves.
protocol Plugin: AnyObject {
    static var manifest: PluginManifest { get }

    init(context: PluginContext)

    var commands: [PluginCommand] { get }
    func activate() throws
    func deactivate()
    func makeSettingsView() -> AnyView?
}

extension Plugin {
    var commands: [PluginCommand] { [] }
    func activate() throws {}
    func deactivate() {}
    func makeSettingsView() -> AnyView? { nil }
}

/// An action a plugin offers in the menu bar, optionally bound to a global shortcut.
struct PluginCommand: Identifiable {
    let id: String
    let title: LocalizedStringKey
    var icon: String?
    var shortcut: HotKey?
    let perform: () -> Void
}
