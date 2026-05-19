#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="${VERSION_FILE:-$ROOT_DIR/VERSION}"

APP_NAME="${APP_NAME:-AirTranslateX}"
BUNDLE_ID="${BUNDLE_ID:-dev.appcaster.AirTranslateX}"
if [[ -z "${VERSION:-}" && -f "$VERSION_FILE" ]]; then
  VERSION="$(tr -d '[:space:]' <"$VERSION_FILE")"
fi
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-${BUILD_NUMBER_DEFAULT:-100}}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-26.0}"
CATEGORY="${CATEGORY:-public.app-category.productivity}"
COPYRIGHT_TEXT="${COPYRIGHT_TEXT:-Copyright © 2026 AirTranslateX. All rights reserved.}"
