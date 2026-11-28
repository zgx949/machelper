import AppKit
import SwiftUI

@main
struct MachelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("machelper", image: "MenuBarIcon") {
            MenuBarContent(host: appDelegate.host, showSetup: appDelegate.showSetup)
        }
        Settings {
            SettingsView(host: appDelegate.host, showSetup: appDelegate.showSetup)
        }
    }
}

/// Owns the plugin host so plugins live for the whole process, independent of scenes.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let host = PluginHost(plugins: PluginCatalog.all)
    private lazy var setup = SetupWindowController(host: host)

    func applicationDidFinishLaunching(_ notification: Notification) {
        host.start()
        if !host.isAccessibilityGranted {
            showSetup()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        host.refreshPermissions()
    }

    func showSetup() {
        setup.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        host.stop()
    }
}

/// One section per running plugin, then permissions, Settings and Quit.
private struct MenuBarContent: View {
    let host: PluginHost
    let showSetup: () -> Void
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ForEach(host.entries.filter { $0.state == .running }) { entry in
            PluginMenuSection(entry: entry, bindings: host.commands.bindings[entry.id] ?? [])
        }

        if host.isWaitingForPermission {
            Divider()
            Button("Grant Accessibility…", action: showSetup)
        }

        Divider()
        Button("Setup Guide…", action: showSetup)
        Button("Settings…") {
            NSApp.activate() // menu bar apps are not frontmost; bring the window forward
            openSettings()
        }
        .keyboardShortcut(",")
        Button("Quit machelper") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

/// A plugin's commands with a divider between groups, followed by its state-dependent items.
private struct PluginMenuSection: View {
    let entry: PluginHost.Entry
    let bindings: [CommandRegistry.Binding]

    var body: some View {
        let items = entry.plugin.menuItems
        if !bindings.isEmpty || !items.isEmpty {
            Section(entry.manifest.name) {
                ForEach(Array(bindings.enumerated()), id: \.element.id) { index, binding in
                    if index > 0, binding.command.group != bindings[index - 1].command.group {
                        Divider()
                    }
                    CommandButton(binding: binding)
                }
                if !items.isEmpty {
                    Divider()
                    ForEach(items) { item in
                        Button(item.title, action: item.perform)
                    }
                }
            }
        }
    }
}

private struct CommandButton: View {
    let binding: CommandRegistry.Binding

    var body: some View {
        let command = binding.command
        Button(action: command.perform) {
            CommandLabel(title: command.title, icon: command.icon)
                .labelStyle(.titleAndIcon) // menus drop Label icons by default
        }
        // Display only: the global hotkey does the work. Conflicting shortcuts are not shown.
        .keyboardShortcut(binding.conflict == nil ? command.shortcut?.keyboardShortcut : nil)
        .disabled(!command.isEnabled())
    }
}
