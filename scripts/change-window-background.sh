#!/usr/bin/env bash

# Paths based on your directory structure
COLOR_FILE="$HOME/.config/rofi/colors.rasi"
BG_DIR="$HOME/.config/rofi/app-launcher/special-case"
BG_FILE="$BG_DIR/window-background.rasi"
ALPHA="0.55"

# 1. Directory & File Recovery
# Ensure the directory exists
mkdir -p "$BG_DIR"

# If the file is missing, create a template 
if [ ! -f "$BG_FILE" ]; then
    echo -e "* {\n    window-background: rgba(0, 0, 0, 1);\n}" > "$BG_FILE"
    echo "Notice: $BG_FILE was missing and has been recreated."
fi

# 2. Extraction & Validation
# Grabs the 'base' hex value from colors.rasi 
HEX_VAL=$(grep -Po 'base:\s*#\K[0-9A-Fa-f]{6}' "$COLOR_FILE")

if [ -z "$HEX_VAL" ]; then
    echo "Error: Could not find valid hex for 'base' in $COLOR_FILE" >&2
    exit 1
fi

# 3. Convert Hex to Dec
R=$(printf "%d" "0x${HEX_VAL:0:2}")
G=$(printf "%d" "0x${HEX_VAL:2:2}")
B=$(printf "%d" "0x${HEX_VAL:4:2}")

RGBA_VAL="rgba($R, $G, $B, $ALPHA)"

# 4. Safe Atomic Update
TEMP_FILE=$(mktemp)

# Replace the window-background value 
sed "s|window-background:.*;|window-background: $RGBA_VAL;|" "$BG_FILE" > "$TEMP_FILE"

if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
    mv "$TEMP_FILE" "$BG_FILE"
    echo "Success: window-background updated to $RGBA_VAL"
else
    echo "Error: Transformation failed. Original file preserved." >&2
    rm -f "$TEMP_FILE"
    exit 1
fi
