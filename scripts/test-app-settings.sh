#!/usr/bin/env bash
# Exercises app preferences and injected login-item operations without changing macOS settings.
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="${TMPDIR:-/tmp}/machelper-app-settings-tests"
mkdir -p "$OUT_DIR/module-cache"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$OUT_DIR/module-cache}"
export SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-$OUT_DIR/module-cache}"

xcrun swiftc -swift-version 5 -default-isolation MainActor \
  -warnings-as-errors \
  -o "$OUT_DIR/app-settings-tests" \
  machelper/Core/AppSettings.swift Tests/AppSettingsTests/main.swift

"$OUT_DIR/app-settings-tests"
