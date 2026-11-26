/// A self-contained capability (clipboard, scroll, window...) owned by `AppCoordinator`.
///
/// Features depend only on `Core` and never on each other.
protocol Feature: AnyObject {
    func start()
    func stop()
}
