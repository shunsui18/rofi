#!/bin/bash

# --- 1. INSTANCE MANAGEMENT ---
# Kill existing sync processes to avoid file-write conflicts
PID_TO_KILL=$(pgrep -f "$(basename "$0")" | grep -v "$$")
if [ -n "$PID_TO_KILL" ]; then
    kill $PID_TO_KILL 2>/dev/null
    sleep 0.5
fi

# --- 2. DYNAMIC PATH CONFIGURATION ---
USER_HOME="$HOME"
WALL_DIR="$USER_HOME/shunscreens/themes/yozakura-yoru/wallpapers"
ASSETS_DIR="$WALL_DIR/wallpaper-assets"
MAP="$WALL_DIR/wallpaper-map.txt"
THUMB_DIR="$WALL_DIR/.thumbnails"
SOCKET="/tmp/mpv-socket"
IMAGE_RASI="$USER_HOME/.config/rofi/special-case/image.rasi"

# --- 3. DYNAMIC FALLBACK LOGIC ---
get_dynamic_fallback() {
    local first_img=$(ls "$ASSETS_DIR" 2>/dev/null | grep -E "\.(jpg|jpeg|png|webp|gif)" | head -n 1)
    if [ -n "$first_img" ]; then
        echo "$ASSETS_DIR/$first_img"
    else
        echo "/usr/share/backgrounds/default.png"
    fi
}

# --- 4. CORRUPTION & HEALTH CHECK ---
# If the file is broken or missing the brace, we rewrite it completely
check_rasi_health() {
    if [[ ! -f "$IMAGE_RASI" ]] || ! grep -q "img:" "$IMAGE_RASI" || ! grep -q "}" "$IMAGE_RASI"; then
        local fallback=$(get_dynamic_fallback)
        mkdir -p "$(dirname "$IMAGE_RASI")"
        echo "* { img: url(\"$fallback\", height); }" > "$IMAGE_RASI"
    fi
}

# --- 5. CORE UPDATE LOGIC ---
update_image() {
    # Only run if mpvpaper socket and map file exist
    if [[ -S "$SOCKET" ]] && [[ -s "$MAP" ]]; then
        # Get current playback time from mpvpaper 
        curr_sec=$(echo '{ "command": ["get_property", "playback-time"] }' | socat - "$SOCKET" 2>/dev/null | jq '.data' | cut -d'.' -f1)
        
        if [[ "$curr_sec" =~ ^[0-9]+$ ]]; then
            # Map the current time to the original asset filename 
            orig_path=$(awk -F'|' -v t="$curr_sec" '$1 <= t {p=$2} END {print p}' "$MAP")
            
            if [[ -n "$orig_path" ]]; then
                base_name=$(basename "${orig_path%.*}")
                final_path="$THUMB_DIR/$base_name.jpg"
                
                local display_img
                if [[ -f "$final_path" ]]; then
                    display_img="$final_path"
                else
                    display_img=$(get_dynamic_fallback)
                fi

                # --- THE FIX: UNIVERSAL REGEX ---
                # This pattern finds 'img: url(' followed by anything up to '), height);'
                # It preserves the rest of the file structure (the braces)
                sed -E "s|img: url\(.*, height\);|img: url(\"$display_img\", height);|g" "$IMAGE_RASI" > "${IMAGE_RASI}.tmp"
                mv "${IMAGE_RASI}.tmp" "$IMAGE_RASI"
            fi
        fi
    fi
}

# --- 6. MAIN LOOP ---
echo "Dynamic Rofi Sync is now active."
check_rasi_health

while true; do
    update_image
    # 1-second poll for responsiveness
    sleep 1 
done