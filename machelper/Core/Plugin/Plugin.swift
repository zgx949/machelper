import AppKit
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
    /// Menu-only items that depend on current state, such as "Ignore “Warp”".
    /// Read while the menu renders, so observable state keeps them up to date.
    var menuItems: [PluginMenuItem] { get }
    func activate() throws
    func deactivate()
    func makeSettingsView() -> AnyView?
}

extension Plugin {
    var commands: [PluginCommand] { [] }
    var menuItems: [PluginMenuItem] { [] }
    func activate() throws {}
    func deactivate() {}
    func makeSettingsView() -> AnyView? { nil }
}

/// An action a plugin offers in the menu bar, optionally bound to a global shortcut.
struct PluginCommand: Identifiable {
    let id: String
    let title: LocalizedStringKey
    var icon: CommandIcon?
    /// Consecutive commands with the same group are listed together, with a divider between groups.
    var group: String?
    var shortcut: HotKey?
    /// Greys the menu item out. Read while the menu renders, so it may depend on observable state.
    var isEnabled: () -> Bool = { true }
    let perform: () -> Void
}

/// An SF Symbol (written as a string literal) or an image the plugin draws itself.
enum CommandIcon: ExpressibleByStringLiteral {
    case symbol(String)
    case image(NSImage)

    init(stringLiteral name: String) {
        self = .symbol(name)
    }
}

/// A menu item without a shortcut.
struct PluginMenuItem: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let perform: () -> Void
}
