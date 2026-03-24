#!/usr/bin/env bash

if pgrep -x "rofi" > /dev/null; then
    killall rofi
    exit 0
fi

ROFI_DIR="$HOME/.config/rofi"
DATA_SCRIPT="$ROFI_DIR/scripts/theme-menu.sh"

chosen=$(eval "$DATA_SCRIPT" | rofi -dmenu -i -p "Theme" -show-icons -theme "$ROFI_DIR/theme-switcher/style.rasi")

if [ -n "$chosen" ]; then
    eval "$DATA_SCRIPT \"$chosen\""
fi