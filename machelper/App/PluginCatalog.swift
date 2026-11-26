/// Every built-in plugin, in menu and Settings order.
///
/// Adding a plugin means adding its folder under `Plugins/` and one line here.
enum PluginCatalog {
    static let all: [any Plugin.Type] = [
        ClipboardPlugin.self,
        WindowPlugin.self,
        ScrollPlugin.self,
        ActionsPlugin.self,
    ]
}
