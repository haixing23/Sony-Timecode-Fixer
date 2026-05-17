#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SonyTimecodeFixer"
BUILD_DIR="$ROOT_DIR/build"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
BINARY="$APP_PATH/Contents/MacOS/$APP_NAME"

"$ROOT_DIR/scripts/build-release.sh"

if [[ ! -x "$BINARY" ]]; then
  echo "✗ 找不到可执行文件: $BINARY"
  exit 1
fi

echo "→ 启动并等待 5 秒..."
"$BINARY" &
APP_PID=$!

sleep 5

if kill -0 "$APP_PID" 2>/dev/null; then
  echo "✓ App 启动并存活 5 秒"
  kill "$APP_PID" 2>/dev/null || true
  wait "$APP_PID" 2>/dev/null || true
else
  echo "✗ App 在 5 秒内退出或 crash"
  exit 1
fi
