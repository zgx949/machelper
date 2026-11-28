# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Each release on GitHub uses the notes from its section here.

## [Unreleased]

## [0.3.0] - 2026-11-28

### Added

- A default General page with Accessibility permission, feature status, app location, launch-at-login and startup-window settings.
- Launch-at-login support using the macOS login-item service, including approval guidance and registration errors.
- A persistent setup guide with installation checks, permission steps, troubleshooting and live feature checks.

### Changed

- Show the main window on startup by default, including when Accessibility is already granted. Close the window or choose Continue in Menu Bar to keep the app running in the background.
- Open the main page, Settings and setup guide in the same reusable window. Missing Accessibility or a feature startup failure still brings up the window when the startup-window preference is off.
- Keep the guide visible after authorization so users can review feature status before continuing.

## [0.2.0] - 2026-11-28

### Added

- App logo, a complete macOS app icon and a matching menu bar icon.
- Bilingual first-launch setup covering installation, Accessibility permission and feature checks, with a guide available from the menu and Settings.
- Installation instructions included in DMG and ZIP downloads.

### Fixed

- Explain Accessibility before requesting it, detect permission changes while running and provide explicit retries for plugins that fail to start.

## [0.1.0] - 2026-11-27

First public release.

### Added

- Menu bar app with a plugin framework: each feature can be switched on or off in Settings, waits for missing permissions and starts automatically once they are granted.
- **Clipboard history**: searchable history of copied text, paste from the menu, skips concealed/transient items (e.g. from password managers).
- **Scroll reversal**: reverse scroll direction separately for mouse and trackpad.
- **Window tiling**: halves, corners, thirds, maximize, center, move to another display and restore the previous frame, with Magnet-style shortcuts.
- **Keyboard scroll actions** (off by default): scroll the frontmost window with shortcuts.
- Shortcut conflict detection: duplicate or unavailable shortcuts are shown in red in Settings.
- Simplified Chinese and English UI, following the system language.

[Unreleased]: https://github.com/zgx949/machelper/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/zgx949/machelper/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/zgx949/machelper/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/zgx949/machelper/releases/tag/v0.1.0
