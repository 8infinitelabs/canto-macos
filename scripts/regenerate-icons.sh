#!/bin/bash
# Regenerate Canto icon assets from the master SVG.
# Requires: rsvg-convert (brew install librsvg)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SVG="$ROOT/scripts/icon.svg"
ASSETS="$ROOT/Canto/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SVG" ]; then
  echo "Error: master SVG not found at $SVG"
  exit 1
fi

if ! command -v rsvg-convert &>/dev/null; then
  echo "Error: rsvg-convert not installed (brew install librsvg)"
  exit 1
fi

declare -a SIZES=(
  "16:icon_16x16.png"
  "32:icon_16x16@2x.png"
  "32:icon_32x32.png"
  "64:icon_32x32@2x.png"
  "128:icon_128x128.png"
  "256:icon_128x128@2x.png"
  "256:icon_256x256.png"
  "512:icon_256x256@2x.png"
  "512:icon_512x512.png"
  "1024:icon_512x512@2x.png"
)

for entry in "${SIZES[@]}"; do
  size="${entry%%:*}"
  filename="${entry##*:}"
  rsvg-convert -w "$size" -h "$size" "$SVG" -o "$ASSETS/$filename"
done

# Marketing 1024 for App Store Connect
rsvg-convert -w 1024 -h 1024 "$SVG" -o "$ROOT/AppStore/icon_marketing_1024.png"

echo "Generated $(ls "$ASSETS"/*.png | wc -l | tr -d ' ') icon files."
