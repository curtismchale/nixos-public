#!/usr/bin/env bash
# rotate-wallpaper.sh — pick a random wallpaper and set it via swww
set -euo pipefail

WALLPAPER_DIR="${1:-$HOME/Pictures/wallpaper}"

if [ ! -d "$WALLPAPER_DIR" ]; then
  echo "Wallpaper directory not found: $WALLPAPER_DIR" >&2
  exit 1
fi

# Collect image files
mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
     -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) )

if [ ${#images[@]} -eq 0 ]; then
  echo "No images found in $WALLPAPER_DIR" >&2
  exit 1
fi

# Pick a random image
chosen="${images[RANDOM % ${#images[@]}]}"

swww img "$chosen" \
  --transition-type grow \
  --transition-duration 2 \
  --transition-fps 60
