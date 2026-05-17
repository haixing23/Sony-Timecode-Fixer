#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-0.0.0-test}"
APP_NAME="SonyTimecodeFixer"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME-$VERSION.dmg"

"$ROOT_DIR/scripts/build-dmg.sh" "$VERSION"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "✗ 找不到 DMG: $DMG_PATH"
  exit 1
fi

echo "→ 挂载 DMG..."
MOUNT_POINT="$(hdiutil attach "$DMG_PATH" -nobrowse | awk -F'\t' '/\/Volumes\// {print $NF; exit}')"
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  echo "✗ DMG 挂载失败"
  exit 1
fi
trap 'hdiutil detach "$MOUNT_POINT" -quiet || true' EXIT

APP_PATH="$MOUNT_POINT/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ DMG 中找不到 app: $APP_PATH"
  exit 1
fi
if [[ ! -L "$MOUNT_POINT/Applications" ]]; then
  echo "✗ DMG 中缺少 Applications 软链"
  exit 1
fi

echo "→ 验证 DMG 内 app 签名..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "→ 拷贝到临时目录模拟安装..."
INSTALL_DIR="$(mktemp -d)"
cp -R "$APP_PATH" "$INSTALL_DIR/"
LOCAL_APP="$INSTALL_DIR/$APP_NAME.app"
xattr -cr "$LOCAL_APP"

echo "→ 启动临时安装 app 并等待 5 秒..."
"$LOCAL_APP/Contents/MacOS/$APP_NAME" &
APP_PID=$!
sleep 5
if kill -0 "$APP_PID" 2>/dev/null; then
  echo "✓ 临时安装 app 启动并存活 5 秒"
  kill "$APP_PID" 2>/dev/null || true
  wait "$APP_PID" 2>/dev/null || true
else
  echo "✗ 临时安装 app 在 5 秒内退出或 crash"
  exit 1
fi

echo "✓ 打包封装测试完成"
