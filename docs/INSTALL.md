# 安装与首次使用 / Installation

需要 macOS 27.2 或更高版本。

## 1. 安装到“应用程序”

从 [Releases](https://github.com/zgx949/machelper/releases/latest) 下载 DMG，打开后将 **machelper** 拖到 **Applications（应用程序）**。如果下载的是 ZIP，先解压，再将 `machelper.app` 移到 `/Applications`。

从“应用程序”打开 machelper。请先完成复制，再授权；不要直接从 DMG 或下载目录运行。安装完成后可以推出 DMG。

## 2. 查看主界面并开启权限

默认启动后会显示主界面，并选中“通用”页，方便确认 App 已运行。这里可以查看辅助功能权限以及功能运行、等待授权和出错的数量；左侧“设置引导”提供安装位置、授权步骤和功能检查，已有权限时也能打开。

辅助功能权限用于反转滚动、移动窗口、键盘滚动和自动粘贴。未授权时，需要该权限的插件会等待；剪贴板历史仍可记录和搜索，自动粘贴需要授权。

1. 点击授权按钮，前往 **系统设置 → 隐私与安全性 → 辅助功能**。
2. 找到 **machelper** 并打开开关，按系统提示认证。如果列表里没有它，点击 **＋**，选择 `/Applications/machelper.app`。
3. App 每秒检查一次权限。授权后等待权限的插件自动启动，窗口保留供你检查结果。如仍有功能出错，点击“重新检查”重试，或在对应插件页面查看原因。

权限开关只能由你在系统设置中开启。参见 [Apple：允许辅助功能 App 访问 Mac](https://support.apple.com/guide/mac-help/mh43185/mac)。

## 3. 检查功能并收起到菜单栏

在有长内容的网页或文档中滚动鼠标滚轮。默认启用“反转鼠标”，触控板方向保持原样。通过 **菜单栏 machelper 图标 → 设置… → 滚动方向**，确认插件显示“运行中”，并按偏好调整鼠标和触控板开关。

machelper 不显示 Dock 图标。点击 **收起并在菜单栏运行** 或关闭窗口，已开启的功能会继续运行，窗口不会在授权后自动消失。菜单栏中的 **打开 machelper…**、**设置…** 和 **安装与授权引导…** 都会打开同一个主窗口；再次打开 App 也可找回窗口。

## 4. 设置启动行为

在 **通用 → 启动** 中按需开启 **开机自启**。开关和批准状态来自 macOS；如果提示需要批准，点击“打开登录项…”并按系统提示完成。注册失败时此页会显示错误，先确认 App 已安装到“应用程序”。

**启动时显示主界面** 默认开启。关闭后，后续启动直接驻留菜单栏；缺少辅助功能权限或有功能启动失败时仍会显示主界面，方便继续设置和排查。关闭此选项不影响从菜单或再次打开 App 来显示窗口。

## 遇到问题

- **首次打开被拦截：** 确认 App 来自本项目 Release 后，前往“系统设置 → 隐私与安全性”，按系统提示选择“仍要打开”。参见 [Apple 的说明](https://support.apple.com/102445)。
- **已授权但仍显示等待权限：** 确认运行的是 `/Applications` 中的版本；在辅助功能列表里关闭再开启 machelper。更新或重新构建后若仍无效，退出 machelper，移除列表里的旧条目，再用 **＋** 添加当前 App 并重新打开。
- **插件显示出错：** 在设置里点击“重试”，或关闭再开启该插件。仍失败时退出并重新打开 App，检查是否运行了多个副本。
- **显示运行中但鼠标方向未变：** 确认“反转鼠标”已打开，并暂停其他滚动修改工具后再试。App 按滚动手势和惯性阶段识别设备；发送这些阶段的 Magic Mouse 等设备会使用“反转触控板”，无阶段的高精度鼠标使用“反转鼠标”。

## English

Requires macOS 27.2 or later.

1. Download the DMG from [Releases](https://github.com/zgx949/machelper/releases/latest). Drag **machelper** to **Applications**. For ZIP downloads, extract the archive and move `machelper.app` to `/Applications`.
2. Launch the copy in Applications. The main window opens to **General** by default, showing Accessibility and feature status. **Setup Guide** in the sidebar explains installation, permission steps and feature checks, and remains available even after authorization. Use the permission button to open **System Settings → Privacy & Security → Accessibility → machelper**. If the app is missing, use **＋** to add `/Applications/machelper.app`. This permission is needed for scroll reversal, window movement, keyboard scrolling and automatic paste. Clipboard history can still record and search without it.
3. The app checks permission every second. Plugins waiting for permission start automatically when access is granted, and the window stays open so you can check the result. Use **Check Again** to retry failed features or select the plugin to inspect its error. Try scrolling a long webpage: mouse reversal is on by default; trackpad reversal is off.
4. Choose **Continue in Menu Bar** or close the window to leave enabled features running. The app has no Dock icon. **Open machelper…**, **Settings…** and **Setup Guide…** in its menu all open the same main window. Opening the app again also shows the window.
5. In **General → Startup**, optionally enable **Launch at Login**. Its state comes from macOS; if approval is required, use **Open Login Items…** to finish enabling it. Registration errors appear on this page. **Show Main Window at Launch** is on by default. Turn it off for future launches to stay in the menu bar; missing Accessibility or a feature startup failure still opens the window for setup and troubleshooting.

The ZIP includes an offline HTML installation guide. The DMG contains only the app and an Applications shortcut.

If macOS blocks the first launch, verify the download came from this project's Release, then follow [Apple's instructions](https://support.apple.com/102445) to use **Open Anyway** in Privacy & Security. See [Apple's Accessibility guide](https://support.apple.com/guide/mac-help/mh43185/mac) for permission settings.

After an update or local rebuild, macOS may require permission again. Toggle the Accessibility switch off and on. If access is still not recognized, quit machelper, remove the old entry, add the current App from Applications, then reopen it. Retry a failed plugin in Settings. If scrolling still does not change while the plugin is running, check its reversal switches and pause other scroll utilities. Magic Mouse and other devices that report gesture or momentum phases use the trackpad setting; high-resolution wheels without these phases use the mouse setting.
