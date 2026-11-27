# machelper

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

每个功能都是一个插件，可在设置里单独开关；缺少权限时会等待，授权后自动启用，无需重启。快捷键冲突会在设置中标红。界面支持简体中文和英文，跟随系统语言。

## 安装 / Install

系统要求：macOS 27.2 或更高。

1. 从 [Releases](https://github.com/zgx949/machelper/releases/latest) 下载 `machelper-<版本>.dmg`，把 **machelper** 拖进“应用程序”。
2. 打开后，在 系统设置 → 隐私与安全性 → 辅助功能 中允许 machelper。

如果该版本未经公证，首次打开会被拦截：右键点击 App 选择“打开”，或执行：

```sh
xattr -dr com.apple.quarantine /Applications/machelper.app
```

> 每次更新后，macOS 可能需要重新授予辅助功能权限（权限按二进制签名授予）。

## 从源码构建 / Build from source

需要 Xcode 27.2+。

```sh
# 构建
xcodebuild -project machelper.xcodeproj -scheme machelper -destination 'platform=macOS' -configuration Debug build

# 逻辑测试（纯逻辑代码，无需 XCTest）
./scripts/test-logic.sh

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
