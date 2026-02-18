#!/usr/bin/env bash
set -euo pipefail

# Render Resources/icons/app-icon.svg into PNGs for Assets.xcassets/AppIcon.appiconset
# Requires: rsvg-convert (librsvg) or ImageMagick's convert

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SVG="$ROOT_DIR/Resources/icons/app-icon.svg"
ICONSET_DIR="$ROOT_DIR/Resources/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SVG" ]; then
  echo "SVG not found: $SVG"
  exit 1
fi

mkdir -p "$ICONSET_DIR"

render() {
  local px=$1
  local out=$2
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$px" -h "$px" "$SVG" -o "$out"
  elif command -v convert >/dev/null 2>&1; then
    convert "$SVG" -background none -resize ${px}x${px} "$out"
  else
    echo "Error: install librsvg (rsvg-convert) or ImageMagick (convert)"
    exit 1
  fi
}

declare -a SPECS=(
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

echo "Generating AppIcon images into $ICONSET_DIR"
for spec in "${SPECS[@]}"; do
  IFS=":" read -r name px <<< "$spec"
  out="$ICONSET_DIR/$name"
  echo " - $name ($px px)"
  render "$px" "$out"
done

echo "Done. You can open Xcode and set the App Icon source to Assets.xcassets -> AppIcon."

exit 0
