import CoreGraphics

/// A synthetic scroll step posted to the window under the mouse pointer.
nonisolated enum ScrollAction: Sendable {
    case up(lines: Int32)
    case down(lines: Int32)

    /// Positive line deltas scroll content up (toward the top), matching CGEvent semantics.
    var lineDelta: Int32 {
        switch self {
        case .up(let lines): lines
        case .down(let lines): -lines
        }
    }

    func perform() {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: lineDelta,
            wheel2: 0,
            wheel3: 0
        ) else { return }
        SyntheticEvent.mark(event) // keeps ScrollEventTap from reversing it
        event.post(tap: .cghidEventTap)
    }
}
