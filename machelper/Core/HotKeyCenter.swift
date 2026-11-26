import AppKit
import Carbon.HIToolbox

/// Registers system-wide hotkeys through Carbon and runs their actions on the main actor.
///
/// Only `CommandRegistry` uses this; plugins declare shortcuts on their commands instead.
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    typealias Token = UInt32

    private static let signature: OSType = 0x4D48_4C50 // "MHLP"

    private var actions: [Token: () -> Void] = [:]
    private var refs: [Token: EventHotKeyRef] = [:]
    private var nextToken: Token = 1

    private init() {
        installDispatcher()
    }

    /// Returns `nil` when the system refuses the shortcut.
    func register(_ hotKey: HotKey, action: @escaping () -> Void) -> Token? {
        let token = nextToken
        nextToken += 1

        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: Self.signature, id: token)
        let status = RegisterEventHotKey(hotKey.keyCode, hotKey.modifiers, id, GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return nil }

        refs[token] = ref
        actions[token] = action
        return token
    }

    func unregister(_ token: Token) {
        if let ref = refs.removeValue(forKey: token) {
            UnregisterEventHotKey(ref)
        }
        actions[token] = nil
    }

    fileprivate func fire(_ token: Token) {
        actions[token]?()
    }

    private func installDispatcher() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotKeyHandler, 1, &spec, nil, nil)
    }
}

/// Carbon delivers hotkey events on the main thread.
private func hotKeyHandler(_: EventHandlerCallRef?, event: EventRef?, _: UnsafeMutableRawPointer?) -> OSStatus {
    var id = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &id
    )
    guard status == noErr else { return status }

    MainActor.assumeIsolated {
        HotKeyCenter.shared.fire(id.id)
    }
    return noErr
}
