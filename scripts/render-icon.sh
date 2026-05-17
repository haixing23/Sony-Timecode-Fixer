#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="$ROOT_DIR/.build/AppIcon.iconset"
ICNS="$ROOT_DIR/Assets/AppIcon.icns"

rm -rf "$ICONSET"
swift "$ROOT_DIR/scripts/render-icon.swift" "$ICONSET" "$ROOT_DIR/Assets/sony-timecode-fixer-icon.svg"

iconutil -c icns "$ICONSET" -o "$ICNS"
cp "$ICNS" "$ROOT_DIR/Assets/sony-timecode-fixer-icon.icns"
echo "$ICNS"
