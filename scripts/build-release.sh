#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SonyTimecodeFixer"
EXECUTABLE_NAME="SonyTimecodeFixer"
BUILD_DIR="$ROOT_DIR/build"
PRODUCTS_DIR="$BUILD_DIR/Build/Products/Release"
APP_PATH="$PRODUCTS_DIR/$APP_NAME.app"

echo "→ 清理旧 build..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

echo "→ 编译 Release..."
swift_sources=()
while IFS= read -r source_file; do
  swift_sources+=("$source_file")
done < <(find "$ROOT_DIR/Sources/SonyTimecodeFixerApp" -name '*.swift' | sort)

DEPLOYMENT_TARGET="13.0"
ARM_BIN="$BUILD_DIR/SonyTimecodeFixer-arm64"
X86_BIN="$BUILD_DIR/SonyTimecodeFixer-x86_64"

swiftc -O -parse-as-library \
  -target "arm64-apple-macosx${DEPLOYMENT_TARGET}" \
  -o "$ARM_BIN" \
  "${swift_sources[@]}"

swiftc -O -parse-as-library \
  -target "x86_64-apple-macosx${DEPLOYMENT_TARGET}" \
  -o "$X86_BIN" \
  "${swift_sources[@]}"

lipo -create "$ARM_BIN" "$X86_BIN" \
  -output "$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
rm -f "$ARM_BIN" "$X86_BIN"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$ROOT_DIR/Resources/sony_timecode_fixer.py" "$APP_PATH/Contents/Resources/sony_timecode_fixer.py"
cp "$ROOT_DIR/Assets/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
chmod +x "$APP_PATH/Contents/Resources/sony_timecode_fixer.py"

plutil -lint "$APP_PATH/Contents/Info.plist" >/dev/null

echo "→ Ad-hoc 签名..."
codesign --force --deep --sign - "$APP_PATH"

echo "→ 验证签名..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "→ 清理扩展属性..."
xattr -cr "$APP_PATH"

echo "✓ 完成: $APP_PATH"
