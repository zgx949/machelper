import AppKit
import Observation
import SwiftUI

/// Keeps menu commands and sidebar navigation pointed at the same window.
@Observable
final class MainNavigation {
    var selection = "general"
}

/// The app opens visibly before the user chooses to leave it running in the menu bar.
final class MainWindowController: NSObject, NSWindowDelegate {
    private let host: PluginHost
    private let appSettings: AppSettings
    private let navigation = MainNavigation()
    private var window: NSWindow?

    init(host: PluginHost, appSettings: AppSettings) {
        self.host = host
        self.appSettings = appSettings
        super.init()
    }

    func show(selection: String = "general") {
        navigation.selection = selection
        host.refreshPermissions()
        appSettings.refreshLoginItemStatus()
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 680),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.title = "machelper"
            window.delegate = self
            window.isReleasedWhenClosed = false
            window.contentMinSize = NSSize(width: 800, height: 560)
            window.contentViewController = NSHostingController(rootView: SettingsView(
                host: host, appSettings: appSettings, navigation: navigation,
                showSetup: { [weak self] in self?.show(selection: "setup") },
                hideToMenuBar: { [weak self] in self?.hideToMenuBar() }
            ))
            // Installing the hosting controller otherwise shrinks to its minimum size.
            window.setContentSize(NSSize(width: 900, height: 680))
            window.center()
            self.window = window
        }
        if window?.isMiniaturized == true { window?.deminiaturize(nil) }
        NSApp.unhide(nil)
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideToMenuBar()
        return false
    }

    private func hideToMenuBar() {
        window?.orderOut(nil)
        // Hand focus back so window shortcuts act on the user's previous app.
        NSApp.hide(nil)
    }
}
