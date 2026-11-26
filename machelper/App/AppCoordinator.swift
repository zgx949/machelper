import Foundation
import Observation

/// Creates every feature and controls their lifecycle.
///
/// Features that need Accessibility start as soon as permission is granted,
/// so the user never has to relaunch after approving the system prompt.
@Observable
final class AppCoordinator {
    let settings: AppSettings
    let clipboard: ClipboardFeature

    private(set) var isAccessibilityTrusted = Permissions.isAccessibilityTrusted

    @ObservationIgnored private let alwaysOn: [Feature]
    @ObservationIgnored private let needsAccessibility: [Feature]
    @ObservationIgnored private var permissionTimer: Timer?

    init(settings: AppSettings = .shared) {
        self.settings = settings
        self.clipboard = ClipboardFeature(settings: settings)
        self.alwaysOn = [clipboard]
        self.needsAccessibility = [
            ScrollFeature(settings: settings),
            WindowFeature(),
            ActionsFeature(),
        ]
    }

    func start() {
        alwaysOn.forEach { $0.start() }

        if isAccessibilityTrusted {
            needsAccessibility.forEach { $0.start() }
        } else {
            Permissions.requestAccessibility()
            waitForAccessibility()
        }
    }

    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        (alwaysOn + needsAccessibility).forEach { $0.stop() }
    }

    private func waitForAccessibility() {
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkAccessibility() }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func checkAccessibility() {
        guard Permissions.isAccessibilityTrusted else { return }
        permissionTimer?.invalidate()
        permissionTimer = nil
        isAccessibilityTrusted = true
        needsAccessibility.forEach { $0.start() }
    }
}
