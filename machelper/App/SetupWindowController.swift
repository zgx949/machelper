import AppKit
import SwiftUI

/// Shows the permission switch prompt until Accessibility is granted.
final class SetupWindowController {
    private let host: PluginHost
    private var window: NSWindow?

    init(host: PluginHost) {
        self.host = host
    }

    func show() {
        host.refreshPermissions()
        guard !host.isAccessibilityGranted else {
            window?.close()
            return
        }
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
                styleMask: [.titled, .closable], backing: .buffered, defer: false
            )
            window.title = String(localized: "Set Up machelper")
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: SetupView(host: host) { [weak self] in
                self?.window?.close()
            })
            window.center()
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}

private struct SetupView: View {
    let host: PluginHost
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image("AppLogo")
                .resizable()
                .frame(width: 88, height: 88)
                .accessibilityHidden(true)
            Text("Turn on the machelper switch")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Button("Go to Settings") { Permissions.requestAndOpenAccessibilitySettings() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
        }
        .padding(32)
        .frame(width: 400, height: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: host.isAccessibilityGranted, initial: true) { _, granted in
            if granted { finish() }
        }
    }
}
