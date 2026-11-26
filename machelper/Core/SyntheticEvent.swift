import CoreGraphics

/// Tags events this app posts itself, so its own event taps can recognise and skip them.
nonisolated enum SyntheticEvent {
    static let marker: Int64 = 0x4D48_4C50 // "MHLP"

    static func mark(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: marker)
    }

    static func isOurs(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == marker
    }
}
