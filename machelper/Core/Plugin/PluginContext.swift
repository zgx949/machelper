import Foundation

/// What the host hands each plugin: its own settings namespace and data folder.
struct PluginContext {
    let id: String
    let store: PluginStore
    /// `~/Library/Application Support/machelper/<id>/`. Plugins create it when they first write.
    let dataDirectory: URL

    init(id: String, defaults: UserDefaults = .standard) {
        self.id = id
        self.store = PluginStore(prefix: "plugins.\(id).", defaults: defaults)
        self.dataDirectory = URL.applicationSupportDirectory
            .appending(path: "machelper", directoryHint: .isDirectory)
            .appending(path: id, directoryHint: .isDirectory)
    }
}

/// `UserDefaults` scoped to one plugin, so plugins cannot overwrite each other's keys.
struct PluginStore {
    let prefix: String
    let defaults: UserDefaults

    func value<Value>(_ key: String, default fallback: Value) -> Value {
        defaults.object(forKey: prefix + key) as? Value ?? fallback
    }

    func set(_ value: Any, for key: String) {
        defaults.set(value, forKey: prefix + key)
    }
}
