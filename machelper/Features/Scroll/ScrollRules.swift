import CoreGraphics

/// Where a scroll event came from, inferred from public event fields.
///
/// Continuous (pixel-precise) or phased events are treated as trackpad; discrete line
/// scrolling as mouse. Magic Mouse and some high-precision mice report as trackpad.
nonisolated enum ScrollDevice: Sendable {
    case mouse, trackpad

    init(isContinuous: Bool, hasPhase: Bool) {
        self = (isContinuous || hasPhase) ? .trackpad : .mouse
    }

    init(_ event: CGEvent) {
        self.init(
            isContinuous: event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0,
            hasPhase: event.getIntegerValueField(.scrollWheelEventScrollPhase) != 0
                || event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0
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
            setIntegerValueField(line, value: -getIntegerValueField(line))
            setDoubleValueField(fixed, value: -getDoubleValueField(fixed))
            setIntegerValueField(point, value: -getIntegerValueField(point))
        }
    }
}
