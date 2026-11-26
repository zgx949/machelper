import AppKit
import SwiftUI

/// Floating, non-activating-style panel hosting `ClipboardListView`.
///
/// Remembers the app that was frontmost when opened so the paste lands there.
final class ClipboardPanel {
    private let store: ClipboardStore
    private var panel: NSPanel?
    private var previousApp: NSRunningApplication?
    private var resignObserver: NSObjectProtocol?

    init(store: ClipboardStore) {
        self.store = store
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() {
        isVisible ? close() : show()
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        let panel = self.panel ?? makePanel()
        self.panel = panel

        // Rebuild content each time so the view's state (query, selection) starts fresh.
        panel.contentView = NSHostingView(rootView: ClipboardListView(
            store: store,
            onPick: { [weak self] item in self?.paste(item) },
            onDismiss: { [weak self] in self?.close() }
        ))
        center(panel)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel?.contentView = nil // release the view tree while hidden
    }

    private func paste(_ item: ClipboardItem) {
        let target = previousApp
        close()
        Paster.paste(item.text, into: target)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }
        return panel
    }

    /// Centers on the screen under the mouse pointer.
    private func center(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let size = panel.contentView?.fittingSize ?? CGSize(width: 520, height: 420)
        panel.setFrame(CGRect(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + visible.height * 0.1,
            width: size.width,
            height: size.height
        ), display: true)
    }
}
