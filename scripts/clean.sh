#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rm -rf "$ROOT_DIR/build" "$ROOT_DIR/dist" "$ROOT_DIR/.build"
find "$ROOT_DIR" -name .DS_Store -delete
echo "✓ 已清理 build/, dist/, .build/"
