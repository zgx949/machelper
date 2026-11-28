#!/usr/bin/env bash
# Compiles logic and scroll-event sources with Tests/LogicTests/main.swift and runs the checks.
# Used locally and by CI. There is no XCTest target yet.
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="${TMPDIR:-/tmp}/machelper-logic-tests"
mkdir -p "$OUT_DIR"

SOURCES=(
  machelper/Plugins/Window/WindowLayout.swift
  machelper/Plugins/Window/WindowHistory.swift
  machelper/Plugins/Scroll/ScrollRules.swift
  machelper/Plugins/Scroll/ScrollEventTap.swift
  machelper/Plugins/Clipboard/ClipboardHistory.swift
  machelper/Core/SyntheticEvent.swift
  Tests/LogicTests/main.swift
)

xcrun swiftc -swift-version 5 -default-isolation MainActor \
  -warnings-as-errors \
  -o "$OUT_DIR/logic-tests" "${SOURCES[@]}"

"$OUT_DIR/logic-tests"
