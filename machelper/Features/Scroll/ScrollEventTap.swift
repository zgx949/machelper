import CoreGraphics
import Foundation
import Synchronization

/// Intercepts scroll-wheel events on a dedicated thread and inverts them per `ScrollRules`.
///
/// The callback must return fast: it only reads the rules under a lock and mutates the event.
/// Requires Accessibility permission; `start()` returns `false` without it.
nonisolated final class ScrollEventTap: @unchecked Sendable {
    private let rules: Mutex<ScrollRules>
    private var port: CFMachPort?

    init(rules: ScrollRules) {
        self.rules = Mutex(rules)
    }

    deinit {
        stop()
    }

    func update(_ newRules: ScrollRules) {
        rules.withLock { $0 = newRules }
    }

    @discardableResult
    func start() -> Bool {
        guard port == nil else { return true }

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: scrollTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ), let source = CFMachPortCreateRunLoopSource(nil, port, 0) else { return false }

        self.port = port
        // Ownership moves to the tap thread; nothing else touches the source afterwards.
        nonisolated(unsafe) let tapSource = source
        let thread = Thread {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), tapSource, .commonModes)
            CFRunLoopRun() // returns once the port is invalidated in stop()
        }
        thread.name = "machelper.scroll-tap"
        thread.qualityOfService = .userInteractive
        thread.start()
        return true
    }

    func stop() {
        guard let port else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        CFMachPortInvalidate(port)
        self.port = nil
    }

    fileprivate func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
        case .scrollWheel:
            guard !SyntheticEvent.isOurs(event) else { break }
            let device = ScrollDevice(event)
            if rules.withLock({ $0.shouldReverse(device) }) {
                event.invertScroll()
            }
        default:
            break
        }
        return .passUnretained(event)
    }
}

nonisolated private func scrollTapCallback(
    _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return .passUnretained(event) }
    return Unmanaged<ScrollEventTap>.fromOpaque(refcon).takeUnretainedValue().handle(type, event)
}
