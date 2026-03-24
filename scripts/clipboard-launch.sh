#!/usr/bin/env bash

ROFI_DIR="$HOME/.config/rofi"

if pgrep -x "rofi" > /dev/null; then
    killall rofi
    exit 0
fi

rofi \
    -modi "clipboard:$ROFI_DIR/scripts/cliphist-rofi-img" \
    -show clipboard \
    -show-icons \
    -theme "$ROFI_DIR/clipboard/style.rasi"