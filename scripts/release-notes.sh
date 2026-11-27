#!/usr/bin/env bash
# Prints the CHANGELOG.md section for a version, followed by install notes.
# Used by the release workflow as the GitHub Release body.
#
# Usage: scripts/release-notes.sh <version>   (e.g. 1.2.0 or v1.2.0)
# Expects Keep a Changelog headings: "## [1.2.0] - 2026-11-27".
# Fails if the version has no section or the section is empty.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/release-notes.sh <version>}"
VERSION="${VERSION#v}"
CHANGELOG=CHANGELOG.md

NOTES="$(awk -v ver="$VERSION" '
  /^## / {
    if (found) exit
    if (index($0, "## [" ver "]") == 1) { found = 1; next }
  }
  # Link reference definitions at the end of the file are not part of any section.
  found && /^\[[^]]+\]: / { exit }
  found { print }
' "$CHANGELOG")"

# Trim leading/trailing blank lines.
NOTES="$(printf '%s\n' "$NOTES" | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"

if [[ -z "${NOTES//[[:space:]]/}" ]]; then
  echo "error: no entry for [$VERSION] in $CHANGELOG" >&2
  exit 1
fi

printf '%s\n' "$NOTES"
sed "s/<version>/$VERSION/g" <<'EOF'

---

### Install

1. Download `machelper-<version>.dmg` and drag **machelper** into Applications.
2. Open it and grant Accessibility access in System Settings → Privacy & Security → Accessibility.

If the build is not notarized, macOS blocks the first launch. Right-click the app and choose **Open**, or run:

```sh
xattr -dr com.apple.quarantine /Applications/machelper.app
```

Verify downloads against `SHA256SUMS.txt` with `shasum -a 256 -c SHA256SUMS.txt`.
EOF
