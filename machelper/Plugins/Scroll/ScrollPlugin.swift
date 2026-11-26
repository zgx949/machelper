import Foundation
import Observation
import SwiftUI

/// Owns the scroll event tap and keeps its rules in sync with `ScrollSettings`.
final class ScrollPlugin: Plugin {
    static let manifest = PluginManifest(
        id: "scroll",
        name: "Scroll Direction",
        icon: "arrow.up.arrow.down",
        summary: "Reverse scrolling separately for mouse and trackpad.",
        permissions: [.accessibility]
    )

    private let settings: ScrollSettings
    private let tap: ScrollEventTap
    private var isRunning = false

    init(context: PluginContext) {
        let settings = ScrollSettings(store: context.store)
        self.settings = settings
        self.tap = ScrollEventTap(rules: settings.rules)
    }

    func activate() throws {
        guard !isRunning else { return }
        tap.update(settings.rules)
        guard tap.start() else { throw ScrollPluginError.tapUnavailable }
        isRunning = true
        observeSettings()
    }

    func deactivate() {
        isRunning = false
        tap.stop()
    }

    func makeSettingsView() -> AnyView? {
        AnyView(ScrollSettingsView(settings: settings))
    }

    /// Re-arms after every change: `withObservationTracking` fires only once per registration.
    private func observeSettings() {
        withObservationTracking {
            _ = settings.rules
        } onChange: { [weak self] in
            let plugin = self
            Task { @MainActor in plugin?.settingsDidChange() }
        }
    }

    private func settingsDidChange() {
        guard isRunning else { return }
        tap.update(settings.rules)
        observeSettings()
    }
}

nonisolated private enum ScrollPluginError: LocalizedError {
    case tapUnavailable

    var errorDescription: String? {
        String(localized: "Could not start the scroll event tap.")
    }
}

/// Scroll preferences, stored in the plugin's own `UserDefaults` namespace.
@Observable
final class ScrollSettings {
    private let store: PluginStore

    var reverseMouse: Bool { didSet { store.set(reverseMouse, for: "reverseMouse") } }
    var reverseTrackpad: Bool { didSet { store.set(reverseTrackpad, for: "reverseTrackpad") } }

    init(store: PluginStore) {
        self.store = store
        reverseMouse = store.value("reverseMouse", default: true)
        reverseTrackpad = store.value("reverseTrackpad", default: false)
    }

    var rules: ScrollRules {
        ScrollRules(reverseMouse: reverseMouse, reverseTrackpad: reverseTrackpad)
    }
}

private struct ScrollSettingsView: View {
    @Bindable var settings: ScrollSettings

    var body: some View {
        Section("Scrolling") {
            Toggle("Reverse mouse", isOn: $settings.reverseMouse)
            Toggle("Reverse trackpad", isOn: $settings.reverseTrackpad)
        }
    }
}
