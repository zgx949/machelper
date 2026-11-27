import AppKit
import Carbon.HIToolbox
import Observation
import SwiftUI

/// Snaps the focused window to screen regions, moves it between displays and restores it.
///
/// Shortcuts match Magnet's, so they carry over unchanged.
@Observable
final class WindowPlugin: Plugin {
    static let manifest = PluginManifest(
        id: "window",
        name: "Window Layouts",
        icon: "rectangle.split.2x1",
        summary: "Snap the focused window to halves, quarters or thirds, move it between displays and restore it.",
        permissions: [.accessibility]
    )

    private let settings: WindowSettings
    private var history = WindowHistory<WindowID>()
    /// Tracked for the menu: "Ignore …" names this app, and display moves need a second screen.
    private var frontmostApp: NSRunningApplication?
    private var screenCount = NSScreen.screens.count
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(context: PluginContext) {
        self.settings = WindowSettings(store: context.store)
    }

    var commands: [PluginCommand] {
        let mods = controlKey | optionKey
        return [
            snap(.leftHalf, "Left Half", "halves", HotKey(kVK_LeftArrow, mods)),
            snap(.rightHalf, "Right Half", "halves", HotKey(kVK_RightArrow, mods)),
            snap(.topHalf, "Top Half", "halves", HotKey(kVK_UpArrow, mods)),
            snap(.bottomHalf, "Bottom Half", "halves", HotKey(kVK_DownArrow, mods)),

            snap(.topLeft, "Top Left", "quarters", HotKey(kVK_ANSI_U, mods)),
            snap(.topRight, "Top Right", "quarters", HotKey(kVK_ANSI_I, mods)),
            snap(.bottomLeft, "Bottom Left", "quarters", HotKey(kVK_ANSI_J, mods)),
            snap(.bottomRight, "Bottom Right", "quarters", HotKey(kVK_ANSI_K, mods)),

            snap(.leftThird, "Left Third", "thirds", HotKey(kVK_ANSI_D, mods)),
            snap(.leftTwoThirds, "Left Two Thirds", "thirds", HotKey(kVK_ANSI_E, mods)),
            snap(.centerThird, "Center Third", "thirds", HotKey(kVK_ANSI_F, mods)),
            snap(.rightTwoThirds, "Right Two Thirds", "thirds", HotKey(kVK_ANSI_T, mods)),
            snap(.rightThird, "Right Third", "thirds", HotKey(kVK_ANSI_G, mods)),

            display("next", "Next Display", "rectangle.righthalf.inset.filled.arrow.right", HotKey(kVK_RightArrow, mods | cmdKey), offset: 1),
            display("previous", "Previous Display", "rectangle.lefthalf.inset.filled.arrow.left", HotKey(kVK_LeftArrow, mods | cmdKey), offset: -1),

            snap(.maximize, "Maximize", "other", HotKey(kVK_Return, mods)),
            snap(.center, "Center", "other", HotKey(kVK_ANSI_C, mods)),
            PluginCommand(
                id: "window.restore",
                title: "Restore",
                icon: "arrow.uturn.backward",
                group: "other",
                shortcut: HotKey(kVK_Delete, mods),
                isEnabled: { [weak self] in self?.history.isEmpty == false }
            ) { [weak self] in self?.restore() },
        ]
    }

    var menuItems: [PluginMenuItem] {
        guard let app = frontmostApp, let bundleID = app.bundleIdentifier else { return [] }
        let name = app.localizedName ?? bundleID
        let isIgnored = settings.isIgnored(bundleID)
        return [
            PluginMenuItem(id: "window.ignore", title: isIgnored ? "Stop Ignoring “\(name)”" : "Ignore “\(name)”") {
                [weak self] in self?.settings.setIgnored(!isIgnored, bundleID)
            },
        ]
    }

    func activate() throws {
        updateFrontmostApp()
        screenCount = NSScreen.screens.count

        let workspace = NSWorkspace.shared.notificationCenter
        let app = NotificationCenter.default
        observers = [
            (workspace, workspace.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) {
                [weak self] _ in MainActor.assumeIsolated { self?.updateFrontmostApp() }
            }),
            (app, app.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) {
                [weak self] _ in MainActor.assumeIsolated { self?.screenCount = NSScreen.screens.count }
            }),
        ]
    }

    func deactivate() {
        for (center, token) in observers {
            center.removeObserver(token)
        }
        observers.removeAll()
    }

    func makeSettingsView() -> AnyView? {
        AnyView(WindowSettingsView(settings: settings))
    }

    // MARK: - Commands

    private func snap(_ layout: WindowLayout, _ title: LocalizedStringKey, _ group: String, _ shortcut: HotKey) -> PluginCommand {
        PluginCommand(
            id: "window.\(layout)",
            title: title,
            icon: .image(LayoutIcon.image(for: layout)),
            group: group,
            shortcut: shortcut,
            isEnabled: { [weak self] in self?.isFrontmostIgnored == false }
        ) { [weak self] in self?.apply(layout) }
    }

    private func display(_ id: String, _ title: LocalizedStringKey, _ icon: CommandIcon, _ shortcut: HotKey, offset: Int) -> PluginCommand {
        PluginCommand(
            id: "window.\(id)Display",
            title: title,
            icon: icon,
            group: "displays",
            shortcut: shortcut,
            isEnabled: { [weak self] in (self?.screenCount ?? 0) > 1 }
        ) { [weak self] in self?.moveToDisplay(offset: offset) }
    }

    // MARK: - Actions

    private func apply(_ layout: WindowLayout) {
        guard let window = arrangeableWindow(), let screen = window.screen else { return }
        move(window, to: layout.frame(for: window.frame, in: screen.visibleFrame))
    }

    /// Screens are ordered left to right; moving past the last one wraps around.
    private func moveToDisplay(offset: Int) {
        let screens = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }
        guard screens.count > 1, let window = arrangeableWindow(),
              let current = window.screen, let index = screens.firstIndex(of: current) else { return }
        let target = screens[(index + offset + screens.count) % screens.count]
        move(window, to: WindowLayout.transfer(window.frame, from: current.visibleFrame, to: target.visibleFrame))
    }

    private func restore() {
        guard let window = arrangeableWindow(), let frame = history.pop(for: window.id) else { return }
        window.setFrame(frame)
    }

    private func move(_ window: FocusedWindow, to frame: CGRect) {
        history.rememberIfNeeded(window.frame, for: window.id)
        window.setFrame(frame)
    }

    private func arrangeableWindow() -> FocusedWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication, !settings.isIgnored(app.bundleIdentifier) else { return nil }
        return FocusedWindow(of: app)
    }

    // MARK: - State

    private var isFrontmostIgnored: Bool {
        settings.isIgnored(frontmostApp?.bundleIdentifier)
    }

    /// Our own windows (Settings) never count as the app to arrange.
    private func updateFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication, app != NSRunningApplication.current else { return }
        frontmostApp = app
    }
}

/// Window preferences, stored in the plugin's own `UserDefaults` namespace.
@Observable
final class WindowSettings {
    private let store: PluginStore

    /// Bundle identifiers of apps whose windows are left alone.
    private(set) var ignoredApps: [String] { didSet { store.set(ignoredApps, for: "ignoredApps") } }

    init(store: PluginStore) {
        self.store = store
        ignoredApps = store.value("ignoredApps", default: [String]())
    }

    func isIgnored(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return ignoredApps.contains(bundleID)
    }

    func setIgnored(_ ignored: Bool, _ bundleID: String) {
        ignoredApps.removeAll { $0 == bundleID }
        if ignored { ignoredApps.append(bundleID) }
    }
}

private struct WindowSettingsView: View {
    let settings: WindowSettings

    var body: some View {
        Section("Ignored Apps") {
            if settings.ignoredApps.isEmpty {
                Text("Use the menu bar to ignore the frontmost app.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(settings.ignoredApps, id: \.self) { bundleID in
                    LabeledContent(Self.appName(bundleID)) {
                        Button("Remove") { settings.setIgnored(false, bundleID) }
                    }
                }
            }
        }
    }

    private static func appName(_ bundleID: String) -> String {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?
            .deletingPathExtension().lastPathComponent ?? bundleID
    }
}
