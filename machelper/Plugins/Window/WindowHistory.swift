import CoreGraphics

/// Frames windows had before they were first moved, for "Restore".
///
/// The original frame is kept until restored, so after several snaps a window
/// still returns to where it started.
struct WindowHistory<Window: Equatable> {
    private var entries: [(window: Window, frame: CGRect)] = []
    private let limit: Int

    init(limit: Int = 50) {
        self.limit = limit
    }

    var isEmpty: Bool { entries.isEmpty }

    mutating func rememberIfNeeded(_ frame: CGRect, for window: Window) {
        guard !entries.contains(where: { $0.window == window }) else { return }
        entries.append((window, frame))
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
    }

    /// Returns and forgets the remembered frame.
    mutating func pop(for window: Window) -> CGRect? {
        guard let index = entries.firstIndex(where: { $0.window == window }) else { return nil }
        return entries.remove(at: index).frame
    }
}
