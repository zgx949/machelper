import Carbon.HIToolbox
import SwiftUI

/// Snaps the focused window to screen regions (⌃⌥ + arrow / ↩ / C).
final class WindowPlugin: Plugin {
    static let manifest = PluginManifest(
        id: "window",
        name: "Window Layouts",
        icon: "rectangle.split.2x1",
        summary: "Move the focused window to halves of the screen.",
        permissions: [.accessibility]
    )

    init(context: PluginContext) {}

    var commands: [PluginCommand] {
        let mods = controlKey | optionKey
        return [
            command(.leftHalf, "Left Half", "rectangle.lefthalf.filled", HotKey(kVK_LeftArrow, mods)),
            command(.rightHalf, "Right Half", "rectangle.righthalf.filled", HotKey(kVK_RightArrow, mods)),
            command(.topHalf, "Top Half", "rectangle.tophalf.filled", HotKey(kVK_UpArrow, mods)),
            command(.bottomHalf, "Bottom Half", "rectangle.bottomhalf.filled", HotKey(kVK_DownArrow, mods)),
            command(.maximize, "Maximize", "rectangle.fill", HotKey(kVK_Return, mods)),
            command(.center, "Center", "rectangle.center.inset.filled", HotKey(kVK_ANSI_C, mods)),
        ]
    }

    private func command(_ layout: WindowLayout, _ title: LocalizedStringKey, _ icon: String, _ shortcut: HotKey) -> PluginCommand {
        PluginCommand(id: "window.\(layout)", title: title, icon: icon, shortcut: shortcut) {
            WindowMover.apply(layout)
        }
    }
}
