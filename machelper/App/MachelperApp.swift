import AppKit
import SwiftUI

@main
struct MachelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("machelper", systemImage: "wand.and.stars") {
            MenuBarContent(host: appDelegate.host)
        }
        Settings {
            SettingsView(host: appDelegate.host)
        }
    }
}

/// Owns the plugin host so plugins live for the whole process, independent of scenes.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let host = PluginHost(plugins: PluginCatalog.all)

    func applicationDidFinishLaunching(_ notification: Notification) {
        host.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        host.stop()
    }
}

/// One section per running plugin, listing its commands with their shortcuts.
private struct MenuBarContent: View {
    let host: PluginHost
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ForEach(host.entries.filter { $0.state == .running }) { entry in
            let bindings = host.commands.bindings[entry.id] ?? []
            if !bindings.isEmpty {
                Section(entry.manifest.name) {
                    ForEach(bindings) { CommandButton(binding: $0) }
                }
            }
        }

        if host.isWaitingForPermission {
            Divider()
            Button("Grant Accessibility…") { Permissions.openAccessibilitySettings() }
        }

        Divider()
        Button("Settings…") {
            NSApp.activate() // menu bar apps are not frontmost; bring the window forward
            openSettings()
        }
        .keyboardShortcut(",")
        Button("Quit machelper") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

private struct CommandButton: View {
    let binding: CommandRegistry.Binding

    var body: some View {
        let command = binding.command
        Button(action: command.perform) {
            if let icon = command.icon {
                Label(command.title, systemImage: icon)
            } else {
                Text(command.title)
            }
        }
        // Display only: the global hotkey does the work. Conflicting shortcuts are not shown.
        .keyboardShortcut(binding.conflict == nil ? command.shortcut?.keyboardShortcut : nil)
    }
}
