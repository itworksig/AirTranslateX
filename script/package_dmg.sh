#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR/script"
# shellcheck source=app_metadata.sh
source "$SCRIPT_DIR/app_metadata.sh"

DIST_DIR="$ROOT_DIR/dist"
WORK_DIR="$DIST_DIR/release-work"
DMG_ROOT="$WORK_DIR/dmg-root"
APP_BUNDLE="$DMG_ROOT/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-universal.dmg"
PRODUCT_NAME="$APP_NAME"
read -r -a ARCHES <<< "${RELEASE_ARCHES:-arm64 x86_64}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"

cd "$ROOT_DIR"

rm -rf "$WORK_DIR" "$DMG_PATH"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$DIST_DIR"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

build_arch() {
  local arch="$1"
  local triple="$arch-apple-macosx$MIN_SYSTEM_VERSION"
  local scratch="$ROOT_DIR/.build/release-$arch"

  swift build \
    --configuration release \
    --disable-sandbox \
    --product "$PRODUCT_NAME" \
    --triple "$triple" \
    --scratch-path "$scratch" >&2

  swift build \
    --configuration release \
    --disable-sandbox \
    --product "$PRODUCT_NAME" \
    --triple "$triple" \
    --scratch-path "$scratch" \
    --show-bin-path 2>/dev/null
}

ARCH_BINARIES=()
for arch in "${ARCHES[@]}"; do
  bin_path="$(build_arch "$arch")/$APP_NAME"
  if [[ ! -x "$bin_path" ]]; then
    echo "Missing build product for $arch at $bin_path" >&2
    exit 1
  fi
  ARCH_BINARIES+=("$bin_path")
done

if [[ "${#ARCH_BINARIES[@]}" -eq 1 ]]; then
  cp "${ARCH_BINARIES[0]}" "$APP_BINARY"
else
  /usr/bin/lipo -create "${ARCH_BINARIES[@]}" -output "$APP_BINARY"
fi
chmod +x "$APP_BINARY"

cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
"$SCRIPT_DIR/write_info_plist.sh" "$INFO_PLIST" release

if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
  /usr/bin/codesign --force --deep --timestamp --options runtime --sign "$CODE_SIGN_IDENTITY" "$APP_BUNDLE"
else
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
  echo "warning: using ad-hoc code signature; notarization is not configured" >&2
fi

ln -s /Applications "$DMG_ROOT/Applications"
/usr/bin/hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
/usr/bin/file "$APP_BINARY"
echo "$DMG_PATH"
