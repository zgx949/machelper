# machelper 架构方案

一个原生 macOS 菜单栏工具，用可开关的插件整合日常能力：剪切板历史、滚动反转、快捷键滚动、窗口分屏。以后要加新能力，再写一个插件即可。

## 目标

- 精简：单进程、常驻菜单栏、空闲时接近零 CPU。
- 清晰：每个功能是一个独立插件，只依赖 `Core`，插件之间互不引用。
- 可开关：每个插件都能在设置里随时打开或关闭，不用重启。

## 技术选型

| 部分 | 技术 |
| --- | --- |
| 语言/界面 | Swift + SwiftUI（内容）+ AppKit（菜单栏、面板、窗口行为） |
| 全局快捷键 | Carbon `RegisterEventHotKey`，由 `CommandRegistry` 统一管理 |
| 剪切板 | `NSPasteboard`，按 `changeCount` 轮询 |
| 滚动反转 | `CGEvent` tap，独立线程 RunLoop |
| 窗口管理 | Accessibility `AXUIElement` + `NSScreen` |
| 开机自启 | ServiceManagement `SMAppService.mainApp`，直接读取系统注册与批准状态 |
| 存储 | 设置用 `UserDefaults`（按插件分命名空间）；历史先用 JSON 文件，之后可换 SQLite/GRDB |

## 工程约束

- 关闭 App Sandbox：AX 控制其他应用窗口、全局 event tap 都需要非沙盒。
- 仅 macOS 平台；`LSUIElement = YES`（不显示 Dock 图标）。
- 需要辅助功能权限的插件会等待授权，授权后自动启动。

## 目录结构

```
machelper/
├── App/              入口、AppDelegate、MainWindowController、PluginCatalog
├── Core/
│   ├── Plugin/       Plugin 协议、PluginContext、PluginHost、CommandRegistry
│   └── …             AppSettings、HotKey、HotKeyCenter、Permissions、SyntheticEvent
├── Plugins/
│   ├── Clipboard/    ClipboardMonitor → ClipboardStore → ClipboardPanel → Paster
│   ├── Window/       WindowLayout（纯函数）+ WindowMover（AX 执行）
│   ├── Scroll/       ScrollRules（纯函数）+ ScrollEventTap（事件拦截）
│   └── Actions/      ScrollAction（快捷键滚动）
└── Settings/         通用设置、引导、插件列表和详情，共用一个主窗口
```

## 主窗口与启动设置

- `AppDelegate` 持有插件 host、全局 `AppSettings` 和可复用的主窗口。默认启动时进入“通用”页；菜单中的主界面、设置和引导入口切换同一窗口的页面。
- `AppSettings.showMainWindowAtLaunch` 默认开启，持久化到 `app.showMainWindowAtLaunch`。关闭后直接驻留菜单栏，缺少辅助功能权限或有插件启动失败时仍显示窗口。再次显式打开 App 时也会显示窗口。
- 关闭窗口或点击“收起并在菜单栏运行”只隐藏窗口，插件与菜单栏继续运行；授权完成不会自动关闭引导。
- “通用”页分别展示辅助功能授权与插件状态。剪贴板记录和搜索不依赖辅助功能；自动粘贴需要该权限。授权状态由 host 每秒刷新，从系统设置返回时也会刷新，激活失败可显式重试。
- 开机自启由 `SMAppService.mainApp` 注册和注销；界面使用系统的已启用、未注册、等待批准、未找到状态，不另存布尔值。注册错误显示在通用页，等待批准时提供登录项设置入口；App 回到前台时刷新状态。

## 插件约定

```swift
protocol Plugin: AnyObject {
    static var manifest: PluginManifest { get }   // id、名称、图标、所需权限、默认是否开启
    init(context: PluginContext)                  // 拿到自己的设置命名空间和数据目录
    var commands: [PluginCommand] { get }         // 菜单项，可带全局快捷键
    func activate() throws                        // 打开开关且权限满足时调用
    func deactivate()                             // 关闭开关时调用
    func makeSettingsView() -> AnyView?           // 插件自己的设置页
}
```

- `PluginHost` 管理状态：已关闭 / 等待权限 / 运行中 / 出错。开关状态会保存。一个插件出错不影响其他插件。
- 插件不直接注册快捷键，只在命令上声明。`CommandRegistry` 在插件运行时注册、关闭时移除，并标出冲突。菜单栏和设置里的快捷键列表都从这里生成。
- 设置存在 `plugins.<id>.` 前缀下，数据在 `Application Support/machelper/<id>/`。
- 输入回调（event tap）只读配置、改数值，不做 IO。
- 计算和系统调用分开，计算部分可单元测试。
- 新增插件：在 `Plugins/` 下加一个文件夹，再在 `PluginCatalog.all` 里加一行。

## 默认快捷键

| 动作 | 快捷键 |
| --- | --- |
| 剪切板面板 | ⌘⇧V |
| 左半屏 / 右半屏 | ⌃⌥← / ⌃⌥→ |
| 上半屏 / 下半屏 | ⌃⌥↑ / ⌃⌥↓ |
| 左上 / 右上 / 左下 / 右下 | ⌃⌥U / ⌃⌥I / ⌃⌥J / ⌃⌥K |
| 左 1/3 / 左 2/3 / 中 1/3 / 右 2/3 / 右 1/3 | ⌃⌥D / ⌃⌥E / ⌃⌥F / ⌃⌥T / ⌃⌥G |
| 下一个 / 上一个显示器 | ⌃⌥⌘→ / ⌃⌥⌘← |
| 最大化 / 居中 / 还原 | ⌃⌥↩ / ⌃⌥C / ⌃⌥⌫ |
| 快捷键滚动（默认关闭，和左下/右下冲突） | ⌃⌥J / ⌃⌥K，加 ⇧ 滚一大段 |

## 后续计划

1. 窗口：补齐 Magnet 的四角、三分屏、切换显示器、还原；菜单项可变灰；动态菜单（忽略某个 App）；用 `WindowLayout` 画布局小图标。
2. 剪切板：支持图片、链接、文件，记录来源 App，改成底部卡片条，按类型筛选。
3. 滚动：按设备设置（经典/自然/反转、步长、上次使用），需要 IOHID 识别设备；模拟滚动的 App 作为单独来源。
4. 设置里修改快捷键。

## 已知限制

- 鼠标和触控板按 `scrollPhase`、`momentumPhase` 区分；无阶段的高精度鼠标仍按鼠标处理。Magic Mouse 等发送手势阶段的设备会被当成触控板，尚未使用 IOHID 识别物理设备。
- 插件编译进 App，不支持运行时加载外部插件。
