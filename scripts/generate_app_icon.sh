#!/usr/bin/env bash
set -euo pipefail

# Generate AppIcon.icns from Resources/icons/app-icon.svg
# Requires: iconutil (system), and one of rsvg-convert (librsvg) or ImageMagick's convert.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SVG="$ROOT_DIR/Resources/icons/app-icon.svg"
ICONSET_DIR="$ROOT_DIR/Resources/AppIcon.iconset"
ICNS_PATH="$ROOT_DIR/Resources/AppIcon.icns"

if [ ! -f "$SVG" ]; then
  echo "SVG not found: $SVG"
  exit 1
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

echo "Using SVG: $SVG"

render_png() {
  local size=$1
  local out=$2
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$size" -h "$size" "$SVG" -o "$out"
  elif command -v convert >/dev/null 2>&1; then
    convert "$SVG" -background none -resize ${size}x${size} "$out"
  else
    echo "Error: need rsvg-convert or ImageMagick 'convert' to render SVG -> PNG"
    exit 1
  fi
}

# Create required iconset sizes (filename -> pixel size)
declare -a ICON_SPECS=(
  "icon_16x16.png:16"
  "icon_16x16@2x.png:32"
  "icon_32x32.png:32"
  "icon_32x32@2x.png:64"
  "icon_128x128.png:128"
  "icon_128x128@2x.png:256"
  "icon_256x256.png:256"
  "icon_256x256@2x.png:512"
  "icon_512x512.png:512"
  "icon_512x512@2x.png:1024"
)

for spec in "${ICON_SPECS[@]}"; do
  IFS=":" read -r name px <<< "$spec"
  out="$ICONSET_DIR/$name"
  echo "Rendering $name ($px px)"
  render_png "$px" "$out"
done

echo "Generating $ICNS_PATH"
rm -f "$ICNS_PATH"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

echo "Generated: $ICNS_PATH"

exit 0
