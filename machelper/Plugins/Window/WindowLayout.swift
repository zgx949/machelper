import CoreGraphics

/// Target placements for the focused window. Pure geometry, no system calls.
///
/// All rects use AppKit screen coordinates (origin at bottom-left).
nonisolated enum WindowLayout: CaseIterable, Sendable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case leftThird, leftTwoThirds, centerThird, rightTwoThirds, rightThird
    case maximize, center

    func frame(for window: CGRect, in screen: CGRect) -> CGRect {
        let half = CGSize(width: screen.width / 2, height: screen.height / 2)
        let third = screen.width / 3

        /// A rect offset by `(dx, dy)` from the screen's bottom-left corner.
        func region(_ dx: CGFloat, _ dy: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
            CGRect(x: screen.minX + dx, y: screen.minY + dy, width: width, height: height)
        }

        switch self {
        case .leftHalf: return region(0, 0, half.width, screen.height)
        case .rightHalf: return region(half.width, 0, half.width, screen.height)
        case .topHalf: return region(0, half.height, screen.width, half.height)
        case .bottomHalf: return region(0, 0, screen.width, half.height)
        case .topLeft: return region(0, half.height, half.width, half.height)
        case .topRight: return region(half.width, half.height, half.width, half.height)
        case .bottomLeft: return region(0, 0, half.width, half.height)
        case .bottomRight: return region(half.width, 0, half.width, half.height)
        case .leftThird: return region(0, 0, third, screen.height)
        case .leftTwoThirds: return region(0, 0, third * 2, screen.height)
        case .centerThird: return region(third, 0, third, screen.height)
        case .rightTwoThirds: return region(third, 0, third * 2, screen.height)
        case .rightThird: return region(third * 2, 0, third, screen.height)
        case .maximize: return screen
        case .center:
            let width = min(window.width, screen.width)
            let height = min(window.height, screen.height)
            return CGRect(x: screen.midX - width / 2, y: screen.midY - height / 2, width: width, height: height)
        }
    }

    /// Moves a window to another screen, keeping its position and size relative to the screen.
    static func transfer(_ window: CGRect, from source: CGRect, to target: CGRect) -> CGRect {
        guard source.width > 0, source.height > 0 else { return window }
        let scaleX = target.width / source.width
        let scaleY = target.height / source.height

        let width = min(window.width * scaleX, target.width)
        let height = min(window.height * scaleY, target.height)
        let x = target.minX + (window.minX - source.minX) * scaleX
        let y = target.minY + (window.minY - source.minY) * scaleY
        return CGRect(
            x: min(max(x, target.minX), target.maxX - width),
            y: min(max(y, target.minY), target.maxY - height),
            width: width,
            height: height
        )
    }
}
