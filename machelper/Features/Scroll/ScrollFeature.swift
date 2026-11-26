import Observation

/// Owns the scroll event tap and keeps its rules in sync with `AppSettings`.
final class ScrollFeature: Feature {
    private let settings: AppSettings
    private let tap: ScrollEventTap
    private var isRunning = false

    init(settings: AppSettings = .shared) {
        self.settings = settings
        self.tap = ScrollEventTap(rules: Self.rules(from: settings))
    }

    func start() {
        guard !isRunning, tap.start() else { return }
        isRunning = true
        observeSettings()
    }

    func stop() {
        isRunning = false
        tap.stop()
    }

    /// Re-arms after every change: `withObservationTracking` fires only once per registration.
    private func observeSettings() {
        withObservationTracking {
            _ = Self.rules(from: settings)
        } onChange: { [weak self] in
            let feature = self
            Task { @MainActor in feature?.settingsDidChange() }
        }
    }

    private func settingsDidChange() {
        guard isRunning else { return }
        tap.update(Self.rules(from: settings))
        observeSettings()
    }

    private static func rules(from settings: AppSettings) -> ScrollRules {
        ScrollRules(reverseMouse: settings.reverseMouse, reverseTrackpad: settings.reverseTrackpad)
    }
}
