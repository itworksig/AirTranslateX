#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="AirTranslate"
BUNDLE_ID="dev.appcaster.AirTranslate"
MIN_SYSTEM_VERSION="26.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>AirTranslate does not automate other apps.</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>AirTranslate transcribes Mac audio so it can show translated captions.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>AirTranslate may use speech services that require audio recognition permission.</string>
  <key>NSSystemAudioCaptureUsageDescription</key>
  <string>AirTranslate captures Mac system audio so it can transcribe and translate what is playing.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

select_code_sign_identity() {
  if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
    printf '%s\n' "$CODE_SIGN_IDENTITY"
    return
  fi

  /usr/bin/security find-identity -v -p codesigning 2>/dev/null |
    /usr/bin/awk -F'"' '/"Apple Development:|Developer ID Application:|Mac Developer:/{ print $2; exit }'
}

SIGN_IDENTITY="$(select_code_sign_identity)"
if [[ -n "$SIGN_IDENTITY" ]]; then
  /usr/bin/codesign --force --deep --timestamp=none --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
else
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
  echo "warning: no persistent code signing identity found; macOS privacy grants may reset after rebuilds" >&2
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  --reset-permissions|reset-permissions)
    /usr/bin/tccutil reset ScreenCapture "$BUNDLE_ID" || true
    /usr/bin/tccutil reset AudioCapture "$BUNDLE_ID" || true
    /usr/bin/tccutil reset SpeechRecognition "$BUNDLE_ID" || true
    echo "Reset AirTranslate privacy grants. Relaunch and approve Screen Recording, System Audio Recording, and Speech Recognition once."
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--reset-permissions]" >&2
    exit 2
    ;;
esac
