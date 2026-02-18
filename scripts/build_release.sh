#!/usr/bin/env bash
set -euo pipefail

# Build script: generates workspace with tuist (if available), builds Release
# macOS app via xcodebuild and copies resulting .app into ./dist/

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="CropSplitImageApp"
CONFIGURATION="Release"
DERIVED_DATA="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"

echo "Root: $ROOT_DIR"

if command -v tuist >/dev/null 2>&1; then
  echo "Running: tuist generate"
  tuist generate
else
  echo "tuist not found — skipping generate step"
fi

# Icon generation removed; use Xcode Asset Catalog (Assets.xcassets) for app icons.

echo "Cleaning previous build..."
rm -rf "$DERIVED_DATA"

echo "Building scheme $SCHEME ($CONFIGURATION)"
if command -v xcbeautify >/dev/null 2>&1; then
  xcodebuild -scheme "$SCHEME" -configuration "$CONFIGURATION" -derivedDataPath "$DERIVED_DATA" clean build | xcbeautify
else
  echo "xcbeautify not found — running xcodebuild without formatting"
  xcodebuild -scheme "$SCHEME" -configuration "$CONFIGURATION" -derivedDataPath "$DERIVED_DATA" clean build
fi

echo "Locating built .app..."
APP_PATH=$(find "$DERIVED_DATA" -type d -name "${SCHEME}.app" -print -quit || true)
if [ -z "$APP_PATH" ]; then
  echo "Error: .app not found in $DERIVED_DATA"
  exit 1
fi

echo "Found app: $APP_PATH"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
cp -R "$APP_PATH" "$DIST_DIR/"

echo "Build complete. App copied to: $DIST_DIR/$(basename "$APP_PATH")"
echo "You can run it with: open '$DIST_DIR/$(basename "$APP_PATH")'"

exit 0
