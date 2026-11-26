import CoreGraphics

/// Target placements for the focused window. Pure geometry, no system calls.
///
/// All rects use AppKit screen coordinates (origin at bottom-left).
enum WindowLayout: CaseIterable {
    case leftHalf, rightHalf, topHalf, bottomHalf, maximize, center

    func frame(for window: CGRect, in screen: CGRect) -> CGRect {
        let halfWidth = screen.width / 2
        let halfHeight = screen.height / 2

        switch self {
        case .leftHalf:
            return CGRect(x: screen.minX, y: screen.minY, width: halfWidth, height: screen.height)
        case .rightHalf:
            return CGRect(x: screen.midX, y: screen.minY, width: halfWidth, height: screen.height)
        case .topHalf:
            return CGRect(x: screen.minX, y: screen.midY, width: screen.width, height: halfHeight)
        case .bottomHalf:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: halfHeight)
        case .maximize:
            return screen
        case .center:
            let width = min(window.width, screen.width)
            let height = min(window.height, screen.height)
            return CGRect(x: screen.midX - width / 2, y: screen.midY - height / 2, width: width, height: height)
        }
    }
}
