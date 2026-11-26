import AppKit
import ApplicationServices

/// A system permission a plugin needs before `PluginHost` activates it.
enum Permission: Hashable {
    case accessibility

    var isGranted: Bool {
        switch self {
        case .accessibility: Permissions.isAccessibilityTrusted
        }
    }
}

/// Accessibility permission is required for window control, event taps and synthetic paste.
enum Permissions {
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system prompt that adds this app to System Settings → Privacy → Accessibility.
    static func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
