import Carbon.HIToolbox
import SwiftUI

/// Keyboard-driven scrolling. Off by default: ⌃⌥J/K are the Window Layouts plugin's bottom corners.
final class ActionsPlugin: Plugin {
    static let manifest = PluginManifest(
        id: "actions",
        name: "Scroll Shortcuts",
        icon: "keyboard",
        summary: "Scroll the window under the pointer from the keyboard.",
        permissions: [.accessibility],
        enabledByDefault: false
    )

    init(context: PluginContext) {}

    var commands: [PluginCommand] {
        let mods = controlKey | optionKey
        let page = mods | shiftKey
        return [
            command("down", "Scroll Down", "arrow.down", HotKey(kVK_ANSI_J, mods), .down(lines: 3)),
            command("up", "Scroll Up", "arrow.up", HotKey(kVK_ANSI_K, mods), .up(lines: 3)),
            command("pageDown", "Scroll Down a Page", "arrow.down.to.line", HotKey(kVK_ANSI_J, page), .down(lines: 15)),
            command("pageUp", "Scroll Up a Page", "arrow.up.to.line", HotKey(kVK_ANSI_K, page), .up(lines: 15)),
        ]
    }

    private func command(
        _ id: String, _ title: LocalizedStringKey, _ icon: CommandIcon, _ shortcut: HotKey, _ action: ScrollAction
    ) -> PluginCommand {
        PluginCommand(id: "actions.\(id)", title: title, icon: icon, shortcut: shortcut) { action.perform() }
    }
}
