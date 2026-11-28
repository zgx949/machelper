import CoreGraphics

/// Where a scroll event came from, inferred from public event fields.
///
/// Gesture or momentum phases identify trackpad-style scrolling. Pixel precision
/// alone does not: high-resolution mouse wheels also send continuous events.
/// Magic Mouse gestures can report the same phases as a trackpad.
nonisolated enum ScrollDevice: Sendable {
    case mouse, trackpad

    init(scrollPhase: Int64, momentumPhase: Int64) {
        self = (scrollPhase != 0 || momentumPhase != 0) ? .trackpad : .mouse
    }

    init(_ event: CGEvent) {
        self.init(
            scrollPhase: event.getIntegerValueField(.scrollWheelEventScrollPhase),
            momentumPhase: event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        )
    }
}

/// Value snapshot of the user's scroll preferences, safe to hand to the event-tap thread.
nonisolated struct ScrollRules: Sendable, Equatable {
    var reverseMouse: Bool
    var reverseTrackpad: Bool

    func shouldReverse(_ device: ScrollDevice) -> Bool {
        switch device {
        case .mouse: reverseMouse
        case .trackpad: reverseTrackpad
        }
    }
}

nonisolated extension CGEvent {
    /// Negates every delta representation so all consumers see the same direction.
    func invertScroll() {
        for (line, fixed, point) in [
            (CGEventField.scrollWheelEventDeltaAxis1, CGEventField.scrollWheelEventFixedPtDeltaAxis1, CGEventField.scrollWheelEventPointDeltaAxis1),
            (CGEventField.scrollWheelEventDeltaAxis2, CGEventField.scrollWheelEventFixedPtDeltaAxis2, CGEventField.scrollWheelEventPointDeltaAxis2),
        ] {
            // Writing the line delta also recalculates the fixed-point and pixel
            // fields. Snapshot all three before any write to avoid negating those
            // recalculated values a second time.
            let lineDelta = getIntegerValueField(line)
            let fixedDelta = getDoubleValueField(fixed)
            let pointDelta = getIntegerValueField(point)
            setIntegerValueField(line, value: -lineDelta)
            setDoubleValueField(fixed, value: -fixedDelta)
            setIntegerValueField(point, value: -pointDelta)
        }
    }
}
