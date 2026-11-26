# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

`machelper` is a native macOS menu bar utility (SwiftUI + AppKit) that replaces several separate tools: clipboard history, scroll reversal, hotkey scroll actions (formerly Hammerspoon scripts) and window tiling. Design rationale and roadmap: `docs/ARCHITECTURE.md`.

One app target / scheme, `machelper`. No third-party dependencies, no test target yet.

## Commands

```sh
# Build (macOS only)
xcodebuild -project machelper.xcodeproj -scheme machelper -destination 'platform=macOS' -configuration Debug build

# Run the built app
open ~/Library/Developer/Xcode/DerivedData/machelper-*/Build/Products/Debug/machelper.app
```

There is no XCTest target yet. Pure-logic files can be checked without one by compiling them with a scratch `main.swift` of assertions:

```sh
xcrun swiftc -swift-version 5 -default-isolation MainActor -o /tmp/logic-tests \
  machelper/Features/Window/WindowLayout.swift machelper/Features/Scroll/ScrollRules.swift \
  machelper/Features/Clipboard/ClipboardHistory.swift machelper/Core/SyntheticEvent.swift /tmp/main.swift && /tmp/logic-tests
```

Accessibility permission is granted per binary signature; after a rebuild macOS may need the app re-approved in System Settings → Privacy & Security → Accessibility.

## Architecture

```
machelper/
├── App/        MachelperApp (@main, MenuBarExtra + Settings scene), AppDelegate, AppCoordinator
├── Core/       Feature protocol, HotKeyCenter (Carbon), Permissions, AppSettings, SyntheticEvent
├── Features/   Clipboard/, Scroll/, Window/, Actions/ — one folder per feature
└── Settings/   SettingsView
```

- Every feature conforms to `Feature` (`start()` / `stop()`) and is created and owned by `AppCoordinator`. Clipboard starts immediately; Scroll, Window and Actions need Accessibility and are started by the coordinator once permission is granted (it polls every 2 s, no relaunch needed).
- **Features depend only on `Core`, never on each other.** Shared cross-feature values go in `Core` (e.g. `SyntheticEvent` marks events posted by `ScrollAction` so `ScrollEventTap` skips them).
- Each feature separates pure logic from system calls: `WindowLayout` / `WindowMover`, `ScrollRules` / `ScrollEventTap`, `ClipboardHistory` / `ClipboardStore` + `ClipboardMonitor` + `Paster`. Keep new logic testable the same way.
- `AppSettings` (`@Observable`, `UserDefaults`) is main-actor only. Code on other threads gets value snapshots: `ScrollFeature` observes settings and pushes `ScrollRules` into the tap via a `Mutex`.
- `ScrollEventTap` runs on its own thread; its callback must stay IO-free and fast, and it re-enables itself on `tapDisabledByTimeout`.
- Clipboard history is JSON at `~/Library/Application Support/machelper/clipboard-history.json`, written on a background queue. Items carrying nspasteboard.org concealed/transient/auto-generated types are not recorded; `Paster` tags its own writes as auto-generated.
- Hotkeys are hard-coded in each feature's `bindings` (and mirrored in `SettingsView`'s shortcut list — keep both in sync).

## Build settings that affect code

- macOS only (`SUPPORTED_PLATFORMS = macosx`), deployment target 27.2 — no `@available` checks needed.
- App Sandbox **off** (required for AX window control and global event taps); hardened runtime on. `LSUIElement = YES` (no Dock icon).
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: everything is `@MainActor` unless marked. Value types used off the main thread (rules, history, event helpers) must be declared `nonisolated`, or their `Codable`/other conformances become main-actor-isolated.
- `SWIFT_VERSION = 5.0` but the build is kept free of Swift 6 concurrency warnings — treat new ones as errors.
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`: import every module whose members a file uses.
- Info.plist is generated; add keys via `INFOPLIST_KEY_*` build settings.

## Localization

- UI supports Simplified Chinese and English, following the system language; any other language falls back to Chinese. This works because the project's development language is `zh-Hans` (`localizations.development` in `project.xcproj`, giving `CFBundleDevelopmentRegion = zh-Hans`).
- Source strings in code are **English keys**; both `en` and `zh-Hans` values live in `machelper/Localizable.xcstrings`. Every new user-facing string needs an entry with both translations.
- Pass text to SwiftUI as literals or `LocalizedStringKey` (not `String`), otherwise it is shown untranslated. Interpolations become format specifiers in the catalog key (e.g. `"Keep %lld items"`).
- To check language resolution, the executable must run from inside an `.app` bundle with `-AppleLanguages '(xx-YY)'`; loading the bundle via `Bundle(path:)` from another binary resolves against that binary's languages and gives misleading results.

## Project file

`machelper.xcodeproj/project.xcproj` is Xcode 27's JSON-like format (trailing commas, no `project.pbxproj`). Sources are a folder reference, so new files under `machelper/` compile automatically. Build settings live only in that file (no `.xcconfig`). Don't commit `xcuserdata/`.
