import Carbon.HIToolbox
import SwiftUI

/// A global keyboard shortcut: a virtual key code plus Carbon modifier flags.
struct HotKey: Hashable {
    let keyCode: UInt32
    let modifiers: UInt32

    init(_ keyCode: Int, _ modifiers: Int) {
        self.keyCode = UInt32(keyCode)
        self.modifiers = UInt32(modifiers)
    }

    /// The same shortcut for SwiftUI menus, or `nil` for keys without a `KeyEquivalent`.
    var keyboardShortcut: KeyboardShortcut? {
        guard let key = Self.keys[keyCode] else { return nil }
        let modifiers = activeModifiers.reduce(into: SwiftUI.EventModifiers()) { $0.insert($1.swiftUI) }
        return KeyboardShortcut(key.equivalent, modifiers: modifiers)
    }

    /// Human-readable form such as "⌃⌥←".
    var displayString: String {
        activeModifiers.map { $0.symbol }.joined() + (Self.keys[keyCode]?.symbol ?? "?")
    }

    private var activeModifiers: [Modifier] {
        Self.modifierOrder.filter { modifiers & UInt32($0.carbon) != 0 }
    }

    // Carbon also declares `EventModifiers`, so the SwiftUI one is spelled out.
    private typealias Modifier = (carbon: Int, swiftUI: SwiftUI.EventModifiers, symbol: String)
    private typealias Key = (equivalent: KeyEquivalent, symbol: String)

    /// Conventional macOS display order.
    private static let modifierOrder: [Modifier] = [
        (controlKey, .control, "⌃"),
        (optionKey, .option, "⌥"),
        (shiftKey, .shift, "⇧"),
        (cmdKey, .command, "⌘"),
    ]

    private static let keys: [UInt32: Key] = {
        var keys: [UInt32: Key] = [
            UInt32(kVK_LeftArrow): (.leftArrow, "←"),
            UInt32(kVK_RightArrow): (.rightArrow, "→"),
            UInt32(kVK_UpArrow): (.upArrow, "↑"),
            UInt32(kVK_DownArrow): (.downArrow, "↓"),
            UInt32(kVK_Return): (.return, "↩"),
            UInt32(kVK_Delete): (.delete, "⌫"),
            UInt32(kVK_Escape): (.escape, "⎋"),
            UInt32(kVK_Space): (.space, "Space"),
        ]
        let letterCodes = [
            kVK_ANSI_A, kVK_ANSI_B, kVK_ANSI_C, kVK_ANSI_D, kVK_ANSI_E, kVK_ANSI_F, kVK_ANSI_G,
            kVK_ANSI_H, kVK_ANSI_I, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L, kVK_ANSI_M, kVK_ANSI_N,
            kVK_ANSI_O, kVK_ANSI_P, kVK_ANSI_Q, kVK_ANSI_R, kVK_ANSI_S, kVK_ANSI_T, kVK_ANSI_U,
            kVK_ANSI_V, kVK_ANSI_W, kVK_ANSI_X, kVK_ANSI_Y, kVK_ANSI_Z,
        ]
        for (code, letter) in zip(letterCodes, "abcdefghijklmnopqrstuvwxyz") {
            keys[UInt32(code)] = (KeyEquivalent(letter), letter.uppercased())
        }
        return keys
    }()
}
