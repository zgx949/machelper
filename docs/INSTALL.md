# 安装与首次使用 / Installation

需要 macOS 27.2 或更高版本。

## 1. 安装到“应用程序”

从 [Releases](https://github.com/zgx949/machelper/releases/latest) 下载 DMG，打开后将 **machelper** 拖到 **Applications（应用程序）**。如果下载的是 ZIP，先解压，再将 `machelper.app` 移到 `/Applications`。

从“应用程序”打开 machelper。请先完成复制，再授权；不要直接从 DMG 或下载目录运行。安装完成后可以推出 DMG。

## 2. 开启辅助功能权限

未授权时启动会显示单屏引导：Logo、“打开 machelper 的开关”和“去打开”按钮；启动时已有权限则不弹窗。辅助功能权限用于反转滚动、移动窗口和模拟粘贴；未授权时，这些插件会等待，不会生效。

1. 点击“去打开”，前往 **系统设置 → 隐私与安全性 → 辅助功能**。
2. 找到 **machelper** 并打开开关，按系统提示认证。如果列表里没有它，点击 **＋**，选择 `/Applications/machelper.app`。
3. App 每秒检查一次权限。授权后引导自动关闭，等待权限的插件自动启动。

权限开关只能由你在系统设置中开启。参见 [Apple：允许辅助功能 App 访问 Mac](https://support.apple.com/guide/mac-help/mh43185/mac)。

## 3. 检查滚动和菜单栏

在有长内容的网页或文档中滚动鼠标滚轮。默认启用“反转鼠标”，触控板方向保持原样。通过 **菜单栏 machelper 图标 → 设置… → 滚动方向**，确认插件显示“运行中”，并按偏好调整鼠标和触控板开关。

machelper 不显示 Dock 图标。关闭引导窗口后，功能继续在菜单栏运行；未授权时可以从菜单重新打开 **安装与授权引导…**。

## 遇到问题

- **首次打开被拦截：** 确认 App 来自本项目 Release 后，前往“系统设置 → 隐私与安全性”，按系统提示选择“仍要打开”。参见 [Apple 的说明](https://support.apple.com/102445)。
- **已授权但仍显示等待权限：** 确认运行的是 `/Applications` 中的版本；在辅助功能列表里关闭再开启 machelper。更新或重新构建后若仍无效，退出 machelper，移除列表里的旧条目，再用 **＋** 添加当前 App 并重新打开。
- **插件显示出错：** 在设置里点击“重试”，或关闭再开启该插件。仍失败时退出并重新打开 App，检查是否运行了多个副本。
- **显示运行中但鼠标方向未变：** 确认“反转鼠标”已打开，并暂停其他滚动修改工具后再试。App 按滚动手势和惯性阶段识别设备；发送这些阶段的 Magic Mouse 等设备会使用“反转触控板”，无阶段的高精度鼠标使用“反转鼠标”。

## English

Requires macOS 27.2 or later.

1. Download the DMG from [Releases](https://github.com/zgx949/machelper/releases/latest). Drag **machelper** to **Applications**. For ZIP downloads, extract the archive and move `machelper.app` to `/Applications`.
2. Launch the copy in Applications. If permission is missing, a single screen shows the logo, **Turn on the machelper switch** and **Go to Settings**. Click the button and enable **System Settings → Privacy & Security → Accessibility → machelper**. If it is missing, use **＋** to add `/Applications/machelper.app`. This permission is needed for scroll reversal, window movement and simulated paste.
3. The app checks permission every second and closes the prompt automatically once access is granted. Plugins waiting for permission start automatically. If access is already enabled at launch, the prompt stays hidden. Try scrolling a long webpage: mouse reversal is on by default; trackpad reversal is off.

The app runs in the menu bar and has no Dock icon. Use its menu to open **Settings…**, or **Setup Guide…** if permission is missing. The ZIP includes an offline HTML installation guide. The DMG contains only the app and an Applications shortcut.

If macOS blocks the first launch, verify the download came from this project's Release, then follow [Apple's instructions](https://support.apple.com/102445) to use **Open Anyway** in Privacy & Security. See [Apple's Accessibility guide](https://support.apple.com/guide/mac-help/mh43185/mac) for permission settings.

After an update or local rebuild, macOS may require permission again. Toggle the Accessibility switch off and on. If access is still not recognized, quit machelper, remove the old entry, add the current App from Applications, then reopen it. Retry a failed plugin in Settings. If scrolling still does not change while the plugin is running, check its reversal switches and pause other scroll utilities. Magic Mouse and other devices that report gesture or momentum phases use the trackpad setting; high-resolution wheels without these phases use the mouse setting.
