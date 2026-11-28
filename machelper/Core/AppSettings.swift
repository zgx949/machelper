import Foundation
import Observation
import ServiceManagement

/// App-wide preferences and the current login-item state reported by macOS.
@Observable
final class AppSettings {
    nonisolated enum LoginItemStatus: Equatable {
        case enabled
        case disabled
        case requiresApproval
        case notFound
    }

    /// Keeps tests away from the user's actual login items.
    struct LoginItemClient {
        let status: () -> LoginItemStatus
        let register: () throws -> Void
        let unregister: () throws -> Void
        let openSettings: () -> Void

        static var system: LoginItemClient {
            LoginItemClient(
                status: {
                    switch SMAppService.mainApp.status {
                    case .enabled: .enabled
                    case .notRegistered: .disabled
                    case .requiresApproval: .requiresApproval
                    case .notFound: .notFound
                    @unknown default: .notFound
                    }
                },
                register: { try SMAppService.mainApp.register() },
                unregister: { try SMAppService.mainApp.unregister() },
                openSettings: { SMAppService.openSystemSettingsLoginItems() }
            )
        }
    }

    private(set) var loginItemStatus: LoginItemStatus
    private(set) var loginItemError: String?

    var showMainWindowAtLaunch: Bool {
        didSet { defaults.set(showMainWindowAtLaunch, forKey: Self.showMainWindowKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let loginItem: LoginItemClient
    private static let showMainWindowKey = "app.showMainWindowAtLaunch"

    init(defaults: UserDefaults = .standard, loginItem: LoginItemClient = .system) {
        self.defaults = defaults
        self.loginItem = loginItem
        loginItemStatus = loginItem.status()
        showMainWindowAtLaunch = defaults.object(forKey: Self.showMainWindowKey) as? Bool ?? true
    }

    /// Pending approval is still registered; the switch must allow unregistering it.
    var launchAtLoginEnabled: Bool {
        loginItemStatus == .enabled || loginItemStatus == .requiresApproval
    }

    /// Permission and activation problems remain discoverable even when the user
    /// normally prefers launching straight into the menu bar.
    func shouldShowMainWindow(isAccessibilityGranted: Bool, hasFailures: Bool) -> Bool {
        showMainWindowAtLaunch || !isAccessibilityGranted || hasFailures
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        refreshLoginItemStatus()
        loginItemError = nil
        guard enabled != launchAtLoginEnabled else { return }
        do {
            if enabled {
                try loginItem.register()
            } else {
                try loginItem.unregister()
            }
        } catch {
            loginItemError = error.localizedDescription
        }
        // A successful registration can still require the user's approval. Never
        // infer success from the requested switch value or persist a second copy.
        loginItemStatus = loginItem.status()
    }

    func refreshLoginItemStatus() {
        let current = loginItem.status()
        if current != loginItemStatus { loginItemError = nil }
        loginItemStatus = current
    }

    func openLoginItemSettings() {
        loginItem.openSettings()
    }

    static var isInstalledInApplications: Bool {
        isApplicationLocation(Bundle.main.bundleURL, homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
    }

    static func isApplicationLocation(_ bundleURL: URL, homeDirectory: URL) -> Bool {
        let components = bundleURL.resolvingSymlinksInPath().standardizedFileURL.pathComponents
        guard bundleURL.pathExtension.lowercased() == "app" else { return false }
        let directories = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            homeDirectory.appendingPathComponent("Applications", isDirectory: true),
        ]
        return directories.contains { directory in
            let parent = directory.resolvingSymlinksInPath().standardizedFileURL.pathComponents
            return components.count > parent.count && components.starts(with: parent)
        }
    }
}
