import Foundation

// Injected clients never register or unregister real login items.
nonisolated(unsafe) var checks = 0
nonisolated(unsafe) var failures = 0

func check(_ condition: Bool, _ message: String, line: Int = #line) {
    checks += 1
    if !condition {
        failures += 1
        print("FAIL (line \(line)): \(message)")
    }
}

enum TestFailure: LocalizedError {
    case denied
    var errorDescription: String? { "Registration denied" }
}

final class LoginItemProbe {
    var status: AppSettings.LoginItemStatus = .disabled
    var resultAfterRegister: AppSettings.LoginItemStatus = .enabled
    var shouldFail = false
    var registrations = 0
    var removals = 0
    var settingsOpened = 0

    var client: AppSettings.LoginItemClient {
        AppSettings.LoginItemClient(
            status: { self.status },
            register: {
                self.registrations += 1
                if self.shouldFail { throw TestFailure.denied }
                self.status = self.resultAfterRegister
            },
            unregister: {
                self.removals += 1
                if self.shouldFail { throw TestFailure.denied }
                self.status = .disabled
            },
            openSettings: { self.settingsOpened += 1 }
        )
    }
}

let suite = "io.github.zgx949.machelper.app-settings-tests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
let probe = LoginItemProbe()
let settings = AppSettings(defaults: defaults, loginItem: probe.client)

check(settings.showMainWindowAtLaunch, "new installations show the main window")
check(!settings.launchAtLoginEnabled, "login item reflects disabled service")
check(probe.registrations == 0 && probe.removals == 0, "initialization never changes login items")
settings.showMainWindowAtLaunch = false
let reopened = AppSettings(defaults: defaults, loginItem: probe.client)
check(!reopened.showMainWindowAtLaunch, "startup-window preference survives relaunch")
reopened.showMainWindowAtLaunch = true
check(AppSettings(defaults: defaults, loginItem: probe.client).showMainWindowAtLaunch,
      "startup-window preference can be restored")

for showAtLaunch in [false, true] {
    settings.showMainWindowAtLaunch = showAtLaunch
    for granted in [false, true] {
        for hasFailures in [false, true] {
            let shouldOpen = settings.shouldShowMainWindow(isAccessibilityGranted: granted, hasFailures: hasFailures)
            if showAtLaunch {
                check(shouldOpen, "explicit show-window preference opens for any health or permission state")
            } else if !granted {
                check(shouldOpen, "missing permission opens a discoverable recovery path")
            } else if hasFailures {
                check(shouldOpen, "plugin failure opens a discoverable recovery path")
            } else {
                check(!shouldOpen, "healthy authorized launch respects hide-window preference")
            }
        }
    }
}

settings.setLaunchAtLogin(true)
check(settings.loginItemStatus == .enabled && settings.launchAtLoginEnabled,
      "registration uses the resulting system state")
check(probe.registrations == 1, "enabling registers once")
settings.setLaunchAtLogin(true)
check(probe.registrations == 1, "already enabled does not register twice")
settings.setLaunchAtLogin(false)
check(settings.loginItemStatus == .disabled && !settings.launchAtLoginEnabled,
      "disabling unregisters the login item")
check(probe.removals == 1, "disabling unregisters once")

probe.resultAfterRegister = .requiresApproval
settings.setLaunchAtLogin(true)
check(settings.loginItemStatus == .requiresApproval, "registration does not claim pending approval is enabled")
check(settings.launchAtLoginEnabled, "pending registration remains switchable off")
settings.setLaunchAtLogin(false)
check(settings.loginItemStatus == .disabled && probe.removals == 2,
      "pending approval can be cancelled")

probe.shouldFail = true
settings.setLaunchAtLogin(true)
check(!settings.launchAtLoginEnabled, "failed registration does not save an enabled preference")
check(settings.loginItemError == "Registration denied", "registration failure remains visible")
settings.refreshLoginItemStatus()
check(settings.loginItemError != nil, "unchanged refresh preserves actionable failure")
probe.status = .enabled
settings.refreshLoginItemStatus()
check(settings.launchAtLoginEnabled, "external system change is reflected")
check(settings.loginItemError == nil, "external recovery clears the old error")
settings.setLaunchAtLogin(false)
check(settings.launchAtLoginEnabled && settings.loginItemError != nil,
      "failed unregister retains true system state and error")
probe.shouldFail = false
settings.setLaunchAtLogin(false)
check(!settings.launchAtLoginEnabled && settings.loginItemError == nil,
      "retry can recover from unregister failure")
probe.status = .notFound
settings.refreshLoginItemStatus()
check(settings.loginItemStatus == .notFound && !settings.launchAtLoginEnabled,
      "missing service is distinct from disabled and does not claim enabled")
settings.openLoginItemSettings()
check(probe.settingsOpened == 1, "approval action opens system login-item settings")

let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)
func installed(_ value: String) -> Bool {
    AppSettings.isApplicationLocation(URL(fileURLWithPath: value), homeDirectory: home)
}
check(installed("/Applications/machelper.app"), "system Applications is accepted")
check(installed("/Applications/Utilities/machelper.app"), "Applications subfolder is accepted")
check(installed("/Users/example/Applications/machelper.app"), "user Applications is accepted")
check(!installed("/Applications-old/machelper.app"), "similar directory prefix is rejected")
check(!installed("/Users/example/ApplicationsBackup/machelper.app"), "user directory prefix is rejected")
check(!installed("/Users/example/Downloads/machelper.app"), "Downloads is rejected")
check(!installed("/Volumes/machelper/machelper.app"), "disk image is rejected")
check(!installed("/Applications/machelper"), "a non-bundle executable is rejected")

print("\(checks - failures)/\(checks) AppSettings checks passed")
exit(failures == 0 ? 0 : 1)
