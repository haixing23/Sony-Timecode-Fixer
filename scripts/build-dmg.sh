#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SonyTimecodeFixer"
VOLUME_NAME="Sony Timecode Fixer"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
DMG_BG="$ROOT_DIR/Assets/dmg/dmg-background@2x.png"
VERSION="${1:-$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0-dev")}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "✗ 缺少 create-dmg。请先安装: brew install create-dmg" >&2
  exit 1
fi

"$ROOT_DIR/scripts/build-release.sh"

APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ Release build 失败,找不到 .app: $APP_PATH"
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_NAME" "$DIST_DIR/rw."*.dmg

echo "→ 使用 create-dmg 生成带背景的 DMG..."
# Background is 2000x1200 @2x → 1000x600 logical. --window-size sets the
# OUTER bounds (incl. ~28px title bar), so add 28 to height so the content
# area exactly matches the background's native size and nothing is clipped
# or scaled.
create-dmg \
  --volname "$VOLUME_NAME" \
  --background "$DMG_BG" \
  --window-pos 200 120 \
  --window-size 1000 660 \
  --icon-size 80 \
  --icon "$APP_NAME.app" 280 460 \
  --app-drop-link 720 460 \
  --hide-extension "$APP_NAME.app" \
  --no-internet-enable \
  "$DIST_DIR/$DMG_NAME" \
  "$APP_PATH"

SHA256="$(LC_ALL=C LANG=C shasum -a 256 "$DIST_DIR/$DMG_NAME" | awk '{print $1}')"
echo "$SHA256" > "$DIST_DIR/$DMG_NAME.sha256"

echo ""
echo "✓ DMG 完成"
echo "  路径: $DIST_DIR/$DMG_NAME"
echo "  版本: $VERSION"
echo "  SHA256: $SHA256"
