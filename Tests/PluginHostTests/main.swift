import Foundation

// Compile with the real host and registry using scripts/test-plugin-host.sh.
// Permissions are injected; no system prompts or privacy settings are changed.
nonisolated(unsafe) var checks = 0
nonisolated(unsafe) var failures = 0

func check(_ condition: Bool, _ message: String, line: Int = #line) {
    checks += 1
    if !condition {
        failures += 1
        print("FAIL (line \(line)): \(message)")
    }
}

final class PermissionProbe {
    var granted = false
}

final class TestPlugin: Plugin {
    static let manifest = PluginManifest(
        id: "lifecycle-test", name: "Lifecycle test", icon: "checkmark",
        summary: "Lifecycle test", permissions: [.accessibility]
    )

    var activations = 0
    var deactivations = 0
    var shouldFail = false

    init(context: PluginContext) {}

    var commands: [PluginCommand] {
        [PluginCommand(id: "test-command", title: "Test command", perform: {})]
    }

    func activate() throws {
        activations += 1
        if shouldFail { throw TestFailure.activation }
    }

    func deactivate() { deactivations += 1 }
}

enum TestFailure: LocalizedError {
    case activation
    var errorDescription: String? { "Simulated activation failure" }
}

final class IndependentPlugin: Plugin {
    static let manifest = PluginManifest(
        id: "independent-test", name: "Independent test", icon: "checkmark",
        summary: "Does not require permissions"
    )

    var activations = 0
    var deactivations = 0

    init(context: PluginContext) {}
    func activate() { activations += 1 }
    func deactivate() { deactivations += 1 }
}

func withDefaults(_ body: @MainActor (UserDefaults) -> Void) {
    let suite = "io.github.zgx949.machelper.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    body(defaults)
}

func testPlugin(_ host: PluginHost) -> TestPlugin {
    host.entries.first(where: { $0.id == TestPlugin.manifest.id })!.plugin as! TestPlugin
}

func state(_ host: PluginHost, id: String = TestPlugin.manifest.id) -> PluginHost.State {
    host.entries.first(where: { $0.id == id })!.state
}

// Missing permission -> grant -> revoke -> grant. Revocation must also remove
// command bindings; a permission-independent plugin keeps running throughout.
withDefaults { defaults in
    let permission = PermissionProbe()
    let host = PluginHost(plugins: [TestPlugin.self, IndependentPlugin.self], defaults: defaults,
                          permissionGranted: { _ in permission.granted })
    defer { host.stop() }
    let plugin = testPlugin(host)
    let independent = host.entries[1].plugin as! IndependentPlugin
    host.start()
    check(state(host) == .waitingForPermission, "initially waits for missing permission")
    check(!host.isAccessibilityGranted, "initial permission status is denied")
    check(plugin.activations == 0, "does not activate before permission is granted")
    check(host.commands.bindings[TestPlugin.manifest.id] == nil, "waiting plugin has no live commands")
    check(state(host, id: IndependentPlugin.manifest.id) == .running, "independent plugin starts without permission")

    permission.granted = true
    host.refreshPermissions()
    check(host.isAccessibilityGranted, "grant is reflected in observable permission status")
    check(state(host) == .running && plugin.activations == 1, "grant activates waiting plugin once")
    check(host.commands.bindings[TestPlugin.manifest.id]?.count == 1, "grant registers plugin commands")
    host.refreshPermissions()
    check(plugin.activations == 1, "unchanged permission does not reactivate running plugin")

    permission.granted = false
    host.refreshPermissions()
    check(!host.isAccessibilityGranted, "revocation is reflected in permission status")
    check(state(host) == .waitingForPermission && plugin.deactivations == 1, "revocation stops the plugin and waits")
    check(host.commands.bindings[TestPlugin.manifest.id] == nil, "revocation removes live commands")
    check(independent.activations == 1 && independent.deactivations == 0, "revocation leaves independent plugin running")
    host.refreshPermissions()
    check(plugin.deactivations == 1, "repeated denied checks do not deactivate twice")

    permission.granted = true
    host.refreshPermissions()
    check(state(host) == .running && plugin.activations == 2, "regrant restores plugin without relaunch")
    check(host.commands.bindings[TestPlugin.manifest.id]?.count == 1, "regrant restores commands")
}

// A real activation error gets cleaned up and stays visible until explicit retry.
withDefaults { defaults in
    let host = PluginHost(plugins: [TestPlugin.self], defaults: defaults, permissionGranted: { _ in true })
    defer { host.stop() }
    let plugin = testPlugin(host)
    plugin.shouldFail = true
    host.start()
    check(host.hasFailures, "activation error is visible")
    check(state(host) == .failed("Simulated activation failure"), "failure reason is preserved")
    check(plugin.activations == 1 && plugin.deactivations == 1, "failed activation releases partial resources")
    check(host.commands.bindings[TestPlugin.manifest.id] == nil, "failed activation exposes no commands")
    host.refreshPermissions()
    host.refreshPermissions()
    check(plugin.activations == 1, "automatic checks do not repeatedly retry failures")
    plugin.shouldFail = false
    host.refreshPermissions(retryFailures: true)
    check(state(host) == .running && plugin.activations == 2, "explicit retry recovers from activation failure")
    check(!host.hasFailures, "successful retry clears failure state")
    check(host.commands.bindings[TestPlugin.manifest.id]?.count == 1, "successful retry registers commands")
}

// Disabling while waiting must survive grant, explicit retry and the next launch.
withDefaults { defaults in
    let permission = PermissionProbe()
    let host = PluginHost(plugins: [TestPlugin.self], defaults: defaults,
                          permissionGranted: { _ in permission.granted })
    host.start()
    host.setEnabled(false, for: TestPlugin.manifest.id)
    permission.granted = true
    host.refreshPermissions(retryFailures: true)
    check(state(host) == .off, "grant and retry do not enable a switched-off plugin")
    check(testPlugin(host).activations == 0, "disabled waiting plugin never activates")
    host.stop()

    let relaunched = PluginHost(plugins: [TestPlugin.self], defaults: defaults, permissionGranted: { _ in true })
    relaunched.start()
    check(state(relaunched) == .off, "disabled preference survives a new host")
    relaunched.setEnabled(true, for: TestPlugin.manifest.id)
    check(state(relaunched) == .running, "user can enable the saved disabled plugin")
    relaunched.stop()

    let enabledAgain = PluginHost(plugins: [TestPlugin.self], defaults: defaults, permissionGranted: { _ in true })
    defer { enabledAgain.stop() }
    enabledAgain.start()
    check(state(enabledAgain) == .running, "enabled preference survives a new host")
    enabledAgain.stop()
    check(testPlugin(enabledAgain).deactivations == 1, "stop deactivates running plugin once")
    check(enabledAgain.commands.bindings.isEmpty, "stop unregisters plugin commands")
}

print("\(checks - failures)/\(checks) PluginHost checks passed")
exit(failures == 0 ? 0 : 1)
