#!/usr/bin/env bash
# lock-and-rotate.sh — lock screen with hyprlock, rotate wallpaper on unlock
set -euo pipefail

# Guard against duplicate hyprlock instances
if pidof hyprlock > /dev/null 2>&1; then
  exit 0
fi

# Lock the screen (blocks until unlock)
hyprlock

# Rotate wallpaper after unlock
bash ~/.local/bin/rotate-wallpaper.sh
