import AppKit

/// Menu icons drawn from `WindowLayout` itself: the screen in a light tone, the target region solid.
enum LayoutIcon {
    private static var cache: [WindowLayout: NSImage] = [:]

    static func image(for layout: WindowLayout) -> NSImage {
        if let image = cache[layout] { return image }
        let image = draw(layout)
        cache[layout] = image
        return image
    }

    private static func draw(_ layout: WindowLayout) -> NSImage {
        let image = NSImage(size: CGSize(width: 18, height: 12), flipped: false) { bounds in
            let screen = bounds.insetBy(dx: 0.5, dy: 0.5)
            let window = screen.insetBy(dx: screen.width * 0.3, dy: screen.height * 0.3) // what "Center" shows

            NSColor.black.withAlphaComponent(0.35).setFill()
            NSBezierPath(roundedRect: screen, xRadius: 2, yRadius: 2).fill()
            NSColor.black.setFill()
            NSBezierPath(roundedRect: layout.frame(for: window, in: screen), xRadius: 1.5, yRadius: 1.5).fill()
            return true
        }
        image.isTemplate = true // follows the menu's text color in light and dark mode
        return image
    }
}
