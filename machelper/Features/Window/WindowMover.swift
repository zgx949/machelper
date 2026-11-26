import AppKit
import ApplicationServices

/// Moves and resizes the frontmost window through the Accessibility API.
enum WindowMover {
    static func apply(_ layout: WindowLayout) {
        guard let window = focusedWindow(), let current = frame(of: window) else { return }
        guard let screen = screen(containing: current) else { return }

        let target = layout.frame(for: current, in: screen.visibleFrame)
        setFrame(target, of: window)
    }

    // MARK: - Accessibility

    private static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private static func frame(of window: AXUIElement) -> CGRect? {
        guard let origin: CGPoint = attribute(kAXPositionAttribute, of: window, type: .cgPoint),
              let size: CGSize = attribute(kAXSizeAttribute, of: window, type: .cgSize) else { return nil }
        return toAppKit(CGRect(origin: origin, size: size))
    }

    /// Size → position → size: the second resize fixes apps that clamp size to the old screen.
    private static func setFrame(_ frame: CGRect, of window: AXUIElement) {
        let axFrame = toAppKit(frame) // the flip is its own inverse
        var origin = axFrame.origin
        var size = axFrame.size
        guard let position = AXValueCreate(.cgPoint, &origin),
              let dimensions = AXValueCreate(.cgSize, &size) else { return }

        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, dimensions)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, dimensions)
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

    // MARK: - Geometry

    /// Converts between AX coordinates (top-left origin) and AppKit coordinates (bottom-left origin).
    private static func toAppKit(_ rect: CGRect) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    private static func screen(containing rect: CGRect) -> NSScreen? {
        NSScreen.screens.max { lhs, rhs in
            lhs.frame.intersection(rect).area < rhs.frame.intersection(rect).area
        } ?? NSScreen.main
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : width * height }
}
