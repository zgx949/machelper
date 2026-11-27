import AppKit
import ApplicationServices

/// The focused window of an app, read and moved through the Accessibility API.
///
/// `frame` uses AppKit coordinates (origin at the bottom-left of the primary screen).
struct FocusedWindow {
    let element: AXUIElement
    let frame: CGRect

    init?(of app: NSRunningApplication) {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        let element = value as! AXUIElement

        guard let origin: CGPoint = Self.attribute(kAXPositionAttribute, of: element, type: .cgPoint),
              let size: CGSize = Self.attribute(kAXSizeAttribute, of: element, type: .cgSize) else { return nil }
        self.element = element
        self.frame = Self.flip(CGRect(origin: origin, size: size))
    }

    var id: WindowID { WindowID(element: element) }

    /// The screen showing the largest part of the window.
    var screen: NSScreen? {
        NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(frame).area < rhs.frame.intersection(frame).area
        } ?? NSScreen.main
    }

    /// Size → position → size: the second resize fixes apps that clamp size to the old screen.
    func setFrame(_ frame: CGRect) {
        let axFrame = Self.flip(frame)
        var origin = axFrame.origin
        var size = axFrame.size
        guard let position = AXValueCreate(.cgPoint, &origin),
              let dimensions = AXValueCreate(.cgSize, &size) else { return }

        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, dimensions)
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, position)
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, dimensions)
    }

    private static func attribute<T>(_ name: String, of element: AXUIElement, type: AXValueType) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }

        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        guard AXValueGetValue(value as! AXValue, type, pointer) else { return nil }
        return pointer.pointee
    }

    /// Converts between AX coordinates (top-left origin) and AppKit coordinates (bottom-left origin).
    /// The conversion is its own inverse.
    private static func flip(_ rect: CGRect) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }
}

/// Identity of a window across lookups; AX elements compare with `CFEqual`.
struct WindowID: Equatable {
    let element: AXUIElement

    static func == (lhs: WindowID, rhs: WindowID) -> Bool {
        CFEqual(lhs.element, rhs.element)
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : width * height }
}
