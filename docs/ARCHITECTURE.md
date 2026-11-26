# machelper 架构方案

一个原生 macOS 菜单栏工具，整合四类日常能力：剪切板历史、滚动反转、快捷键动作、窗口分屏。

## 目标

- 精简：单进程、常驻菜单栏、空闲时接近零 CPU。
- 清晰：每个功能是独立模块，互不依赖，由 `AppCoordinator` 装配。
- 可替换：存储、快捷键、设备识别都隔离在小接口后面。

## 技术选型

| 部分 | 技术 |
| --- | --- |
| 语言/界面 | Swift + SwiftUI（内容）+ AppKit（菜单栏、面板、窗口行为） |
| 全局快捷键 | Carbon `RegisterEventHotKey`（原型）→ 可换 KeyboardShortcuts |
| 剪切板 | `NSPasteboard`，按 `changeCount` 轮询 |
| 滚动反转 | `CGEvent` tap，独立线程 RunLoop |
| 窗口管理 | Accessibility `AXUIElement` + `NSScreen` |
| 存储 | 设置用 `UserDefaults`；历史先用 JSON 文件（原型）→ 可换 SQLite/GRDB |

## 工程约束

- 关闭 App Sandbox：AX 控制其他应用窗口、全局 event tap 都需要非沙盒。
- 仅 macOS 平台；`LSUIElement = YES`（不显示 Dock 图标）。
- 首次启动引导授予「辅助功能」权限。

## 目录结构

```
machelper/
├── App/              入口、AppDelegate、菜单栏、AppCoordinator
├── Core/             HotKeyCenter、Permissions、AppSettings
├── Features/
│   ├── Clipboard/    ClipboardMonitor → ClipboardStore → ClipboardPanel → Paster
│   ├── Scroll/       ScrollReverser（event tap）
│   ├── Window/       WindowLayout（纯函数计算）+ WindowMover（AX 执行）
│   └── Actions/      ScrollActions 等快捷键动作
└── Settings/         SwiftUI 设置界面
```

## 模块约定

```swift
protocol Feature: AnyObject {
    func start()
    func stop()
}
```

- 模块只依赖 `Core`，不依赖其他模块。
- 输入回调（event tap）只做读配置 + 改数值，绝不做 IO。
- 布局计算与系统调用分离，计算部分可单元测试。

## 默认快捷键（原型）

| 动作 | 快捷键 |
| --- | --- |
| 剪切板面板 | ⌘⇧V |
| 左半屏 / 右半屏 | ⌃⌥← / ⌃⌥→ |
| 填满 / 居中 | ⌃⌥↩ / ⌃⌥C |
| 上 / 下半屏 | ⌃⌥↑ / ⌃⌥↓ |

## 已知限制与后续

- 鼠标/触控板区分基于 `isContinuous`，少数高精度鼠标可能误判。
- 暂不支持：图片/文件剪切板、拖边吸附、跨 Spaces 移动窗口、通用脚本。
