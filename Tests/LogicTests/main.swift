import CoreGraphics
import Foundation

// Pure-logic checks, compiled together with the app's logic sources by
// `scripts/test-logic.sh`. There is no XCTest target; failures exit non-zero.

nonisolated(unsafe) var failures = 0
nonisolated(unsafe) var checks = 0

func check(_ condition: @autoclosure () -> Bool, _ message: String, line: Int = #line) {
    checks += 1
    if !condition() {
        failures += 1
        print("FAIL (line \(line)): \(message)")
    }
}

func checkEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String, line: Int = #line) {
    check(actual == expected, "\(message): expected \(expected), got \(actual)", line: line)
}

// MARK: - WindowLayout

let screen = CGRect(x: 0, y: 0, width: 1200, height: 800)
let offsetScreen = CGRect(x: 1200, y: 100, width: 1200, height: 800)
let window = CGRect(x: 10, y: 20, width: 400, height: 300)

checkEqual(WindowLayout.leftHalf.frame(for: window, in: screen), CGRect(x: 0, y: 0, width: 600, height: 800), "leftHalf")
checkEqual(WindowLayout.rightHalf.frame(for: window, in: screen), CGRect(x: 600, y: 0, width: 600, height: 800), "rightHalf")
checkEqual(WindowLayout.topHalf.frame(for: window, in: screen), CGRect(x: 0, y: 400, width: 1200, height: 400), "topHalf (AppKit y-up)")
checkEqual(WindowLayout.bottomHalf.frame(for: window, in: screen), CGRect(x: 0, y: 0, width: 1200, height: 400), "bottomHalf")
checkEqual(WindowLayout.topLeft.frame(for: window, in: screen), CGRect(x: 0, y: 400, width: 600, height: 400), "topLeft")
checkEqual(WindowLayout.topRight.frame(for: window, in: screen), CGRect(x: 600, y: 400, width: 600, height: 400), "topRight")
checkEqual(WindowLayout.bottomLeft.frame(for: window, in: screen), CGRect(x: 0, y: 0, width: 600, height: 400), "bottomLeft")
checkEqual(WindowLayout.bottomRight.frame(for: window, in: screen), CGRect(x: 600, y: 0, width: 600, height: 400), "bottomRight")
checkEqual(WindowLayout.leftThird.frame(for: window, in: screen), CGRect(x: 0, y: 0, width: 400, height: 800), "leftThird")
checkEqual(WindowLayout.leftTwoThirds.frame(for: window, in: screen), CGRect(x: 0, y: 0, width: 800, height: 800), "leftTwoThirds")
checkEqual(WindowLayout.centerThird.frame(for: window, in: screen), CGRect(x: 400, y: 0, width: 400, height: 800), "centerThird")
checkEqual(WindowLayout.rightTwoThirds.frame(for: window, in: screen), CGRect(x: 400, y: 0, width: 800, height: 800), "rightTwoThirds")
checkEqual(WindowLayout.rightThird.frame(for: window, in: screen), CGRect(x: 800, y: 0, width: 400, height: 800), "rightThird")
checkEqual(WindowLayout.maximize.frame(for: window, in: screen), screen, "maximize")
checkEqual(WindowLayout.center.frame(for: window, in: screen), CGRect(x: 400, y: 250, width: 400, height: 300), "center keeps size")
checkEqual(
    WindowLayout.center.frame(for: CGRect(x: 0, y: 0, width: 5000, height: 5000), in: screen), screen,
    "center clamps oversized window"
)
checkEqual(WindowLayout.leftHalf.frame(for: window, in: offsetScreen), CGRect(x: 1200, y: 100, width: 600, height: 800), "layouts respect screen origin")
checkEqual(WindowLayout.topRight.frame(for: window, in: offsetScreen), CGRect(x: 1800, y: 500, width: 600, height: 400), "corner respects screen origin")

for layout in WindowLayout.allCases {
    let frame = layout.frame(for: window, in: offsetScreen)
    check(offsetScreen.contains(frame), "\(layout) stays inside the screen")
}

// MARK: - WindowLayout.transfer

let small = CGRect(x: 0, y: 0, width: 1000, height: 500)
let large = CGRect(x: 1000, y: 0, width: 2000, height: 1000)
checkEqual(
    WindowLayout.transfer(CGRect(x: 100, y: 50, width: 400, height: 200), from: small, to: large),
    CGRect(x: 1200, y: 100, width: 800, height: 400),
    "transfer scales position and size"
)
checkEqual(
    WindowLayout.transfer(CGRect(x: 200, y: 100, width: 1600, height: 800), from: large, to: small),
    CGRect(x: 0, y: 50, width: 800, height: 400),
    "transfer clamps x into target, keeps in-bounds y"
)
let degenerate = CGRect(x: 0, y: 0, width: 0, height: 0)
checkEqual(WindowLayout.transfer(window, from: degenerate, to: large), window, "transfer from empty screen is a no-op")

// MARK: - WindowHistory

var history = WindowHistory<Int>(limit: 2)
check(history.isEmpty, "history starts empty")
history.rememberIfNeeded(CGRect(x: 1, y: 1, width: 1, height: 1), for: 1)
history.rememberIfNeeded(CGRect(x: 9, y: 9, width: 9, height: 9), for: 1)
checkEqual(history.pop(for: 1), CGRect(x: 1, y: 1, width: 1, height: 1), "keeps the original frame")
checkEqual(history.pop(for: 1), nil, "pop forgets the frame")
history.rememberIfNeeded(.zero, for: 1)
history.rememberIfNeeded(.zero, for: 2)
history.rememberIfNeeded(.zero, for: 3)
checkEqual(history.pop(for: 1), nil, "oldest entry dropped past the limit")
check(history.pop(for: 3) != nil, "newest entry kept")

// MARK: - ClipboardHistory

var clips = ClipboardHistory()
clips.record("a", limit: 3)
clips.record("b", limit: 3)
clips.record("a", limit: 3)
checkEqual(clips.items.map(\.text), ["a", "b"], "repeated text moves to top")
clips.record("  \n", limit: 3)
checkEqual(clips.items.count, 2, "blank text ignored")
clips.record("c", limit: 3)
clips.record("d", limit: 3)
checkEqual(clips.items.map(\.text), ["d", "c", "a"], "limit drops oldest")
clips.record("e", limit: 0)
checkEqual(clips.items.count, 0, "zero limit keeps nothing")

var searchable = ClipboardHistory()
searchable.record("Hello World", limit: 10)
searchable.record("goodbye", limit: 10)
checkEqual(searchable.search("hello").map(\.text), ["Hello World"], "search is case-insensitive")
checkEqual(searchable.search("  ").count, 2, "blank query returns everything")
if let first = searchable.items.first {
    searchable.remove(first.id)
}
checkEqual(searchable.items.map(\.text), ["Hello World"], "remove by id")
searchable.clear()
check(searchable.items.isEmpty, "clear")

let encoded = try JSONEncoder().encode(clips)
checkEqual(try JSONDecoder().decode(ClipboardHistory.self, from: encoded), clips, "history round-trips through JSON")

// MARK: - ScrollRules

checkEqual(ScrollDevice(isContinuous: false, hasPhase: false), .mouse, "discrete scroll is mouse")
checkEqual(ScrollDevice(isContinuous: true, hasPhase: false), .trackpad, "continuous scroll is trackpad")
checkEqual(ScrollDevice(isContinuous: false, hasPhase: true), .trackpad, "phased scroll is trackpad")
let rules = ScrollRules(reverseMouse: true, reverseTrackpad: false)
check(rules.shouldReverse(.mouse), "reverse mouse")
check(!rules.shouldReverse(.trackpad), "keep trackpad")

// MARK: - SyntheticEvent

if let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: 3, wheel2: 0, wheel3: 0) {
    check(!SyntheticEvent.isOurs(event), "unmarked event is not ours")
    SyntheticEvent.mark(event)
    check(SyntheticEvent.isOurs(event), "marked event is ours")
} else {
    check(false, "could not create a scroll event")
}

print("\(checks - failures)/\(checks) checks passed")
exit(failures == 0 ? 0 : 1)
