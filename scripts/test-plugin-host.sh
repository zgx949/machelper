#!/usr/bin/env bash
# Tests the real plugin lifecycle and command registry without system permissions
# or global hotkeys. Run on macOS with the same Swift toolchain as the app.
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="${TMPDIR:-/tmp}/machelper-plugin-host-tests"
mkdir -p "$OUT_DIR/module-cache"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$OUT_DIR/module-cache}"
export SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-$OUT_DIR/module-cache}"

SOURCES=(
  machelper/Core/Permissions.swift
  machelper/Core/HotKey.swift
  machelper/Core/Plugin/Plugin.swift
  machelper/Core/Plugin/PluginContext.swift
  machelper/Core/Plugin/CommandRegistry.swift
  machelper/Core/Plugin/PluginHost.swift
  Tests/PluginHostTests/HotKeyCenterStub.swift
  Tests/PluginHostTests/main.swift
)

xcrun swiftc -swift-version 5 -default-isolation MainActor \
  -warnings-as-errors \
  -o "$OUT_DIR/plugin-host-tests" "${SOURCES[@]}"

"$OUT_DIR/plugin-host-tests"
