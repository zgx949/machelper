import AppKit
import SwiftUI

@main
struct MachelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("machelper", systemImage: "wand.and.stars") {
            MenuBarContent(coordinator: appDelegate.coordinator)
        }
        Settings {
            SettingsView(coordinator: appDelegate.coordinator)
        }
    }
}

/// Owns the coordinator so features live for the whole process, independent of scenes.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }
}

private struct MenuBarContent: View {
    let coordinator: AppCoordinator
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Clipboard History") { coordinator.clipboard.showPanel() }
            .keyboardShortcut("v", modifiers: [.command, .shift])

        if !coordinator.isAccessibilityTrusted {
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
