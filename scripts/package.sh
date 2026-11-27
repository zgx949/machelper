#!/usr/bin/env bash
# Builds a Release of machelper and packages it as .zip and .dmg in dist/.
#
# Usage: scripts/package.sh <version> [build-number]
#   version       e.g. 1.2.0 or v1.2.0 (sets MARKETING_VERSION)
#   build-number  integer, default 1 (sets CURRENT_PROJECT_VERSION)
#
# Signing:      set MACOS_SIGNING_IDENTITY (e.g. "Developer ID Application: Name (TEAMID)")
#               to sign with a Developer ID; otherwise the app is ad-hoc signed.
# Notarization: runs when NOTARY_APPLE_ID, NOTARY_TEAM_ID and NOTARY_PASSWORD
#               (an app-specific password) are set. Requires a Developer ID signature.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/package.sh <version> [build-number]}"
VERSION="${VERSION#v}"
BUILD_NUMBER="${2:-1}"
APP_NAME=machelper
DIST=dist
DERIVED=build/DerivedData
STAGE=build/stage

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?([-.][0-9A-Za-z.]+)?$ ]]; then
  echo "error: '$VERSION' is not a version like 1.2.0" >&2
  exit 1
fi

rm -rf "$DIST" "$STAGE"
mkdir -p "$DIST" "$STAGE"

echo "==> Building $APP_NAME $VERSION ($BUILD_NUMBER)"
xcodebuild -project machelper.xcodeproj -scheme machelper \
  -destination 'generic/platform=macOS' -configuration Release \
  -derivedDataPath "$DERIVED" \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" \
  build

ditto "$DERIVED/Build/Products/Release/$APP_NAME.app" "$STAGE/$APP_NAME.app"
APP="$STAGE/$APP_NAME.app"

NOTARIZE=0
if [[ -n "${NOTARY_APPLE_ID:-}" && -n "${NOTARY_TEAM_ID:-}" && -n "${NOTARY_PASSWORD:-}" ]]; then
  NOTARIZE=1
fi

if [[ -n "${MACOS_SIGNING_IDENTITY:-}" ]]; then
  echo "==> Signing with Developer ID"
  codesign --force --options runtime --timestamp --sign "$MACOS_SIGNING_IDENTITY" "$APP"
else
  echo "==> No signing identity, ad-hoc signing"
  codesign --force --sign - "$APP"
  if [[ $NOTARIZE == 1 ]]; then
    echo "warning: notarization needs a Developer ID signature, skipping" >&2
    NOTARIZE=0
  fi
fi
codesign --verify --strict --verbose=2 "$APP"

notarize() {
  xcrun notarytool submit "$1" --wait \
    --apple-id "$NOTARY_APPLE_ID" --team-id "$NOTARY_TEAM_ID" --password "$NOTARY_PASSWORD"
}

if [[ $NOTARIZE == 1 ]]; then
  echo "==> Notarizing app"
  ditto -c -k --keepParent "$APP" "$STAGE/notarize.zip"
  notarize "$STAGE/notarize.zip"
  xcrun stapler staple "$APP"
  rm "$STAGE/notarize.zip"
fi

ZIP="$DIST/$APP_NAME-$VERSION.zip"
DMG="$DIST/$APP_NAME-$VERSION.dmg"

echo "==> Creating $ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "==> Creating $DMG"
DMG_ROOT="$STAGE/dmg"
mkdir -p "$DMG_ROOT"
ditto "$APP" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create -volname "$APP_NAME $VERSION" -srcfolder "$DMG_ROOT" -ov -format UDZO "$DMG"

if [[ -n "${MACOS_SIGNING_IDENTITY:-}" ]]; then
  codesign --force --timestamp --sign "$MACOS_SIGNING_IDENTITY" "$DMG"
fi
if [[ $NOTARIZE == 1 ]]; then
  echo "==> Notarizing dmg"
  notarize "$DMG"
  xcrun stapler staple "$DMG"
fi

(cd "$DIST" && shasum -a 256 "$APP_NAME-$VERSION.zip" "$APP_NAME-$VERSION.dmg" > SHA256SUMS.txt)

echo "==> Done"
ls -lh "$DIST"
