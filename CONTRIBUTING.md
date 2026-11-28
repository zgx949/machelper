# Contributing to machelper

感谢参与！Issue 和 PR 用中文或英文都可以。

## 开发环境

- macOS 27.2+，Xcode 27.2+
- 无第三方依赖，直接打开 `machelper.xcodeproj` 即可
- 项目约定（插件结构、并发、本地化等）见 [CLAUDE.md](CLAUDE.md) 和 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## 提交 PR 前

```sh
./scripts/test-logic.sh
./scripts/test-plugin-host.sh
xcodebuild -project machelper.xcodeproj -scheme machelper -destination 'platform=macOS' -configuration Debug build
```

- 构建不能有新的 Swift 6 并发警告。
- 纯逻辑与系统调用分开写；新增的纯逻辑请在 `Tests/LogicTests/main.swift` 中补充检查（新文件需加到 `scripts/test-logic.sh` 的源文件列表）。
- 新增的界面文字需要在 `machelper/Localizable.xcstrings` 中同时提供 `en` 和 `zh-Hans` 翻译。
- 新增插件：在 `machelper/Plugins/` 下建一个文件夹，并在 `PluginCatalog.all` 中加一行。插件之间不能互相依赖。
- 在 `CHANGELOG.md` 的 `## [Unreleased]` 下记录面向用户的改动（Added / Changed / Fixed / Removed）。

## 提交信息

首行用祈使句简要说明改动（英文，约 50 字符以内），需要时空一行后写细节。

## 版本与发布

版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。发布由维护者打 `vX.Y.Z` tag 触发，流程见 [README](README.md#发布流程--releasing)。
