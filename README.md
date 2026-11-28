# machelper

<img src="machelper/Assets.xcassets/AppLogo.imageset/AppLogo@2x.png" width="96" height="96" alt="machelper Logo">

[![CI](https://github.com/zgx949/machelper/actions/workflows/ci.yml/badge.svg)](https://github.com/zgx949/machelper/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/zgx949/machelper?include_prereleases&sort=semver)](https://github.com/zgx949/machelper/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

一个原生的 macOS 菜单栏小工具（SwiftUI + AppKit），把剪贴板历史、滚动方向反转、快捷键滚动和窗口分屏合进一个 App。无第三方依赖。

A native macOS menu bar utility that bundles clipboard history, scroll reversal, keyboard scrolling and window tiling into one app. No third-party dependencies.

## 功能 / Features

| 插件 | 说明 |
| --- | --- |
| 剪贴板历史 | 可搜索的文本历史，从菜单直接粘贴；自动跳过密码管理器等标记为隐藏/临时的内容 |
| 滚动反转 | 鼠标和触控板分别设置滚动方向 |
| 窗口分屏 | 左右/上下半屏、四角、三分屏、最大化、居中、移到其他显示器、还原，快捷键与 Magnet 一致 |
| 键盘滚动 | 用快捷键滚动前台窗口（默认关闭，与窗口插件的 ⌃⌥J/K 冲突） |

每个功能都是一个插件，可在设置里单独开关；缺少权限时会等待，授权后自动启用，无需重启。默认先展示主界面的“通用”页，可查看权限与功能状态、设置开机自启及启动时是否显示窗口。快捷键冲突会在设置中标红。界面支持简体中文和英文，跟随系统语言。

## 安装 / Install

系统要求：macOS 27.2 或更高。

1. 从 [Releases](https://github.com/zgx949/machelper/releases/latest) 下载 `machelper-<版本>.dmg`，把 **machelper** 拖进 **Applications（应用程序）**。ZIP 用户先解压，再把 App 移到“应用程序”。
2. 从“应用程序”打开 machelper，先进入主界面的“通用”页。缺少权限时，点击授权按钮或打开“安装与授权引导”：**系统设置 → 隐私与安全性 → 辅助功能 → 打开 machelper 开关**。列表里没有时，点 **＋** 添加 `/Applications/machelper.app`。
3. 授权后等待中的功能自动启用，窗口会保留供你检查。在网页中试滚动：默认只反转鼠标，触控板方向保持原样。点击 **收起并在菜单栏运行** 或关闭窗口，App 会收起并继续工作。

machelper 常驻屏幕顶部菜单栏，不显示 Dock 图标；菜单中的“打开 machelper…”、“设置…”和“安装与授权引导…”都会回到同一个主窗口，已有权限时也可查看引导。“通用”页可设置开机自启；若系统要求额外批准，可直接前往“登录项”完成。默认启动时显示主界面；关闭该选项后从菜单栏启动，缺少辅助功能权限或有功能启动失败时仍会显示窗口。ZIP 内附带可双击阅读的双语安装指南，DMG 只包含 App 和 Applications 入口。详细排查见 [安装与首次使用](docs/INSTALL.md)。

Download the DMG, drag **machelper** to **Applications**, then launch it from there. The main window opens to **General**, with permission and feature status, **Launch at Login**, and **Show Main Window at Launch**. Allow **System Settings → Privacy & Security → Accessibility → machelper**; waiting features start automatically, and the guide stays open for review. Choose **Continue in Menu Bar** or close the window to keep working in the background. The menu reopens the same window, with no Dock icon. Turning off the startup window keeps future launches in the menu bar unless Accessibility is missing or a feature fails to start. See the [installation guide](docs/INSTALL.md#english) for ZIP installation and troubleshooting.

如果首次打开被 macOS 拦截，确认下载来自本项目的 Release 后，按 [Apple 的打开说明](https://support.apple.com/102445) 到“隐私与安全性”点击“仍要打开”。更新或本地重新构建后，可能需要重新授予辅助功能权限，方法见安装指南。

## 从源码构建 / Build from source

需要 Xcode 27.2+。

```sh
# 构建
xcodebuild -project machelper.xcodeproj -scheme machelper -destination 'platform=macOS' -configuration Debug build

# 逻辑测试（纯逻辑代码，无需 XCTest）
./scripts/test-logic.sh
./scripts/test-plugin-host.sh
./scripts/test-app-settings.sh

# 本地打包 .dmg / .zip 到 dist/
./scripts/package.sh 0.1.0
```

架构说明见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)，贡献指南见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 发布流程 / Releasing

1. 在 [CHANGELOG.md](CHANGELOG.md) 中把 `[Unreleased]` 下的内容移到新版本标题下，例如 `## [0.2.0] - 2026-12-01`，并更新底部链接。
2. 提交后打 tag 并推送：

   ```sh
   git tag v0.2.0 && git push origin v0.2.0
   ```

3. GitHub Actions 会运行测试、按 tag 设置版本号、打包 `.dmg` / `.zip` / `SHA256SUMS.txt`，并用 CHANGELOG 中对应的段落创建 Release。带 `-` 的 tag（如 `v0.2.0-beta.1`）会标为预发布。

### 签名与公证（可选）

不配置时使用 ad-hoc 签名。在仓库 Settings → Secrets and variables → Actions 中添加以下 secrets 后，会自动使用 Developer ID 签名并公证：

| Secret | 说明 |
| --- | --- |
| `MACOS_CERTIFICATE_P12` | Developer ID Application 证书导出的 `.p12`，base64 编码 |
| `MACOS_CERTIFICATE_PASSWORD` | `.p12` 的密码 |
| `MACOS_SIGNING_IDENTITY` | 如 `Developer ID Application: Name (TEAMID)` |
| `NOTARY_APPLE_ID` | Apple ID 邮箱 |
| `NOTARY_TEAM_ID` | Team ID |
| `NOTARY_PASSWORD` | App 专用密码 |

## 许可证 / License

[MIT](LICENSE)
