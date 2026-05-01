#!/usr/bin/env bash
# =============================================================================
# install.sh — Yozakura Rofi config installer
# Place this file at the repo root (alongside app-launcher/, styles/, etc.).
# Run without arguments for interactive menu, or pass flags directly.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors & symbols
# ---------------------------------------------------------------------------
PINK='\033[38;5;218m'
LAVENDER='\033[38;5;183m'
GREEN='\033[38;5;157m'
RED='\033[38;5;210m'
YELLOW='\033[38;5;222m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "  ${LAVENDER}›${RESET} $*"; }
success() { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET} $*"; }
error()   { echo -e "  ${RED}✗${RESET} $*" >&2; }
banner()  {
    echo
    echo -e "${PINK}${BOLD}  夜桜 Yozakura — Rofi Config Installer${RESET}"
    echo -e "${DIM}  ────────────────────────────────────────${RESET}"
    echo
}

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
FLAVOR=""
BACKUP=""
INTERACTIVE=false

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF

  Usage: $(basename "$0") [OPTIONS]

  Options:
    --theme  <flavor>   Theme flavor: yoru | hiru
    --backup <bool>     Back up existing config: yes | no
    -h, --help          Show this help message

  Run without any options to launch the interactive menu.

  Examples:
    $(basename "$0") --theme yoru --backup yes
    $(basename "$0") --theme hiru --backup no

EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --theme)
            [[ -z "${2-}" ]] && { error "--theme requires a value (yoru|hiru)."; exit 1; }
            FLAVOR="${2,,}"; shift 2 ;;
        --backup)
            [[ -z "${2-}" ]] && { error "--backup requires a value (yes|no)."; exit 1; }
            BACKUP="${2,,}"; shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            error "Unknown option: $1"
            usage; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# If no flags given, launch interactive menu
# ---------------------------------------------------------------------------
if [[ -z "$FLAVOR" && -z "$BACKUP" ]]; then
    INTERACTIVE=true
fi

banner

if [[ "$INTERACTIVE" == true ]]; then

    # — Flavor picker —
    echo -e "  ${BOLD}Select a flavor:${RESET}"
    echo -e "  ${PINK}1)${RESET} 🌸  Yoru ${DIM}(night — deep moonlit palette)${RESET}"
    echo -e "  ${LAVENDER}2)${RESET} ☀️   Hiru ${DIM}(day  — warm ivory canvas)${RESET}"
    echo
    while true; do
        read -rp $'  \e[2mFlavor\e[0m [1/2] (default: 1): ' flavor_input
        flavor_input="${flavor_input:-1}"
        case "$flavor_input" in
            1) FLAVOR="yoru"; break ;;
            2) FLAVOR="hiru"; break ;;
            *) echo -e "  ${RED}Please enter 1 or 2.${RESET}" ;;
        esac
    done

    echo

    # — Backup picker —
    echo -e "  ${BOLD}Back up existing ~/.config/rofi?${RESET}"
    echo -e "  ${PINK}1)${RESET} Yes ${DIM}(saves current config to ~/.config/rofi.bak)${RESET}"
    echo -e "  ${LAVENDER}2)${RESET} No  ${DIM}(existing files will be overwritten)${RESET}"
    echo
    while true; do
        read -rp $'  \e[2mBackup\e[0m [1/2] (default: 1): ' backup_input
        backup_input="${backup_input:-1}"
        case "$backup_input" in
            1) BACKUP="yes"; break ;;
            2) BACKUP="no";  break ;;
            *) echo -e "  ${RED}Please enter 1 or 2.${RESET}" ;;
        esac
    done

    echo
    echo -e "${DIM}  ────────────────────────────────────────${RESET}"
    echo

fi

# ---------------------------------------------------------------------------
# Validate flag-mode values (menu always produces valid values)
# ---------------------------------------------------------------------------
if [[ "$FLAVOR" != "yoru" && "$FLAVOR" != "hiru" ]]; then
    error "Invalid --theme '$FLAVOR'. Valid values: yoru, hiru"
    exit 1
fi

BACKUP="${BACKUP,,}"
if [[ "$BACKUP" != "yes" && "$BACKUP" != "no" ]]; then
    error "Invalid --backup '$BACKUP'. Valid values: yes, no"
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve script location — works both locally and via bash <(curl ...)
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == /proc/self/fd/* || "${BASH_SOURCE[0]}" == /dev/fd/* ]]; then
    REPO_ROOT="$(mktemp -d)"
    trap 'rm -rf "$REPO_ROOT"' EXIT
    info "Fetching repo into temp dir..."
    git clone --depth=1 https://github.com/shunsui18/rofi.git "$REPO_ROOT" &>/dev/null
    success "Repo fetched."
    echo
else
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# ---------------------------------------------------------------------------
# Validate source layout
# ---------------------------------------------------------------------------
REQUIRED_DIRS=(app-launcher clipboard scripts styles theme-switcher)
for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$REPO_ROOT/$dir" ]]; then
        error "Expected directory not found: $REPO_ROOT/$dir"
        error "Make sure install.sh is at the repo root alongside all config folders."
        exit 1
    fi
done

COLORS_FILE="$REPO_ROOT/styles/colors-${FLAVOR}.rasi"
if [[ ! -f "$COLORS_FILE" ]]; then
    error "Color file not found: $COLORS_FILE"
    exit 1
fi

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROFI_CONF_DIR="$HOME/.config/rofi"
BACKUP_DIR="$HOME/.config/rofi.bak"

# ---------------------------------------------------------------------------
# Backup existing config if requested
# ---------------------------------------------------------------------------
if [[ "$BACKUP" == "yes" && -d "$ROFI_CONF_DIR" ]]; then
    info "Backing up existing config → $BACKUP_DIR"
    if [[ -d "$BACKUP_DIR" ]]; then
        warn "Backup directory already exists — removing old backup first."
        rm -rf "$BACKUP_DIR"
    fi
    cp -r "$ROFI_CONF_DIR" "$BACKUP_DIR"
    success "Backup saved to $BACKUP_DIR"
    echo
elif [[ "$BACKUP" == "no" && -d "$ROFI_CONF_DIR" ]]; then
    warn "Existing ~/.config/rofi will be overwritten — no backup taken."
    echo
fi

# ---------------------------------------------------------------------------
# Create destination & copy all config folders
# ---------------------------------------------------------------------------
info "Creating config directory: $ROFI_CONF_DIR"
mkdir -p "$ROFI_CONF_DIR"

COPY_DIRS=(app-launcher clipboard scripts styles theme-switcher)
for dir in "${COPY_DIRS[@]}"; do
    info "Copying $dir/ → $ROFI_CONF_DIR/$dir/"
    cp -r "$REPO_ROOT/$dir" "$ROFI_CONF_DIR/"
done

# ---------------------------------------------------------------------------
# Make all scripts executable
# ---------------------------------------------------------------------------
info "Setting executable bit on scripts/"
chmod +x "$ROFI_CONF_DIR/scripts/"*

# ---------------------------------------------------------------------------
# Create the colors.rasi symlink pointing at the chosen flavor
# ---------------------------------------------------------------------------
SYMLINK_PATH="$ROFI_CONF_DIR/colors.rasi"
SYMLINK_TARGET="styles/colors-${FLAVOR}.rasi"   # relative — portable

info "Setting colors.rasi → $SYMLINK_TARGET"
[[ -e "$SYMLINK_PATH" || -L "$SYMLINK_PATH" ]] && rm -f "$SYMLINK_PATH"
ln -s "$SYMLINK_TARGET" "$SYMLINK_PATH"

# ---------------------------------------------------------------------------
# Create color-map.rasi symlinks in app-launcher/ and theme-switcher/
# ---------------------------------------------------------------------------
COLOR_MAP_TARGET="color-map-${FLAVOR}.rasi"   # relative — portable

for module in app-launcher theme-switcher; do
    CM_SYMLINK="$ROFI_CONF_DIR/$module/color-map.rasi"
    info "Setting $module/color-map.rasi → $COLOR_MAP_TARGET"
    [[ -e "$CM_SYMLINK" || -L "$CM_SYMLINK" ]] && rm -f "$CM_SYMLINK"
    ln -s "$COLOR_MAP_TARGET" "$CM_SYMLINK"
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo -e "${DIM}  ────────────────────────────────────────${RESET}"
success "${BOLD}Flavor        ${RESET}: yozakura-${FLAVOR}"
success "${BOLD}colors.rasi   ${RESET}: → $SYMLINK_TARGET"
success "${BOLD}color-map.rasi${RESET}: → $COLOR_MAP_TARGET"
success "${BOLD}Backup        ${RESET}: $( [[ "$BACKUP" == "yes" ]] && echo "$BACKUP_DIR" || echo "none" )"
success "${BOLD}Config dir    ${RESET}: $ROFI_CONF_DIR"
echo -e "${DIM}  ────────────────────────────────────────${RESET}"
echo
echo -e "  ${PINK}Done. Re-launch Rofi to apply the theme.${RESET}"
echo