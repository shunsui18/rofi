#!/usr/bin/env bash

if pgrep -x "rofi" > /dev/null; then
    killall -9 rofi
else
    rofi \
        -show drun \
        -theme ~/.config/rofi/app-launcher/style.rasi \
        & > /dev/null
fi