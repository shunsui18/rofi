#!/usr/bin/env bash

THEME_DIR="$HOME/shunscreens/themes"

# --- THEME LIST ---
# Add your new themes here following the pattern:
# "Display Name|Icon_Path|Script_to_Execute"
themes=(
    "Catppuccin Mocha|${THEME_DIR}/catppuccin-mocha/icon.png|${THEME_DIR}/catppuccin-mocha/apply-theme.sh"
    "Dracula|${THEME_DIR}/dracula/icon.png|${THEME_DIR}/dracula/apply-theme.sh"
    "Everforest Dark|${THEME_DIR}/everforest-dark/icon.png|${THEME_DIR}/everforest-dark/apply-theme.sh" 
    "Rosé Pine Dawn|${THEME_DIR}/rose-pine-dawn/icon.png|${THEME_DIR}/rose-pine-dawn/apply-theme.sh"
    "Yozakura-yoru|${THEME_DIR}/yozakura-yoru/icon.png|${THEME_DIR}/yozakura-yoru/apply-theme.sh"
)
# ------------------

# If no argument is passed, output the list for Rofi
if [ -z "$1" ]; then
    for theme in "${themes[@]}"; do
        IFS="|" read -r name icon script <<< "$theme"
        # Output: Name + null byte + icon metadata
        echo -en "${name}\0icon\x1f${icon}\n"
    done
else
    # If an argument is passed, treat it as a selection and execute
    for theme in "${themes[@]}"; do
        IFS="|" read -r name icon script <<< "$theme"
        if [[ "$name" == "$1" ]]; then
            # Expand tilde if present and execute
            eval "${script//\~/$HOME}"
            break
        fi
    done
fi