#!/bin/bash
# ==============================================================================
# Standalone Backup & Symlink Script for Hyprland-blizz
# Designed to be triggered from hypr-welcome
# ==============================================================================

# Define color codes
RED='\033[0;31m'
BLUE='\033[1;34m'
GREEN='\033[38;2;149;209;137m'
NC='\033[0m' # No Color

# Function to launch an Alacritty terminal if not already launched
launch_alacritty_terminal() {
    if [ -z "$ALACRITTY_WINDOW_ID" ]; then
        if ! alacritty -e "$0" &>/dev/null; then
            echo "Failed to launch Alacritty. Please check your Alacritty installation."
            exit 1
        fi
        exit
    fi
}
launch_alacritty_terminal

username=$(whoami)
backup_dir="/home/$username/.config/backup"

# ==============================================================================
# PART 1: SAFE BACKUP FUNCTION
# ==============================================================================
show_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}"
}


show_message "░█▀▀█ █▀▀█ █▀▀ █─█ █──█ █▀▀█ 　 ░█─░█ █──█ █▀▀█ █▀▀█ █── █▀▀█ █▀▀▄ █▀▀▄" "$BLUE"
show_message "░█▀▀▄ █▄▄█ █── █▀▄ █──█ █──█ 　 ░█▀▀█ █▄▄█ █──█ █▄▄▀ █── █▄▄█ █──█ █──█" "$BLUE"
show_message "░█▄▄█ ▀──▀ ▀▀▀ ▀─▀ ─▀▀▀ █▀▀▀ 　 ░█─░█ ▄▄▄█ █▀▀▀ ▀─▀▀ ▀▀▀ ▀──▀ ▀──▀ ▀▀▀─" "$BLUE"
echo
show_message "Starting safe backup of configurations..." "$GREEN"

mkdir -p "$backup_dir"

backup() {
    local source_dir="$1"
    local dest_dir="$2"
    mkdir -p "$dest_dir"
    cp -r "$source_dir" "$dest_dir"
}

# Folders to backup
folders=("alacritty" "btop" "cava" "dunst" "hypr" "hypr-welcome" "kitty" "Kvantum" "networkmanager-dmenu" "nwg-look" "pacseek" "pipewire" "qt6ct" "ranger" "sddm-config-editor" "systemd" "Thunar" "waybar" "waypaper" "wlogout" "wofi" "xsettingsd" "gtk-2.0" "gtk-3.0" "gtk-4.0" "starship" "swaync" "Code - OSS")

for folder in "${folders[@]}"; do
    folder_path="/home/$username/.config/$folder"
    backup_path="$backup_dir/$folder"
    
    # SPECIAL HANDLING FOR VS CODE (Code - OSS)
    if [ "$folder" == "Code - OSS" ]; then
        mkdir -p "$backup_path/User"
        if [ -f "$folder_path/User/settings.json" ]; then
            cp "$folder_path/User/settings.json" "$backup_path/User/settings.json"
            show_message "Backed up VS Code settings.json" "$GREEN"
        else
            show_message "VS Code settings.json not found, skipping." "$RED"
        fi
    else
        # Normal backup for other folders
        if [ -d "$folder_path" ]; then
            backup "$folder_path" "$backup_path"
            show_message "Backed up $folder" "$GREEN"
        else
            show_message "$folder not found, skipping." "$RED"
        fi
    fi
done

show_message "Backup completed successfully!" "$GREEN"
echo

# ==============================================================================
# PART 2: SYMLINK CREATION & VERIFICATION
# ==============================================================================
show_message "Checking and creating system symlinks..." "$BLUE"

# Function to check if all required symlinks exist
check_symlinks() {
    local symlinks=("hypr-welcome" "hypr-eos-kill-yad-zombies" "hypr_check_updates" "select-wallpaper")
    local all_exist=true
    for symlink in "${symlinks[@]}"; do
        if [ ! -L "/usr/bin/$symlink" ]; then
            all_exist=false
            break
        fi
    done
    if $all_exist; then
        return 0
    else
        return 1
    fi
}

# Check if the symlinks exist
if check_symlinks; then
    show_message "All required symlinks already exist." "$GREEN"
else
    show_message "Creating missing symlinks..." "$BLUE"
    
    # Ensure we are in the right directory
    cd "$HOME/.config/hypr-welcome/scripts" || { echo "Failed to change to scripts directory." >&2; exit 1; }

    # 1. Hypr-Welcome internal scripts
    welcome_script="$HOME/.config/hypr-welcome/scripts/hypr-welcome"
    sudo ln -sf "$welcome_script" "/usr/bin/hypr-welcome"

    kill_script="$HOME/.config/hypr-welcome/scripts/hypr-eos-kill-yad-zombies"
    sudo ln -sf "$kill_script" "/usr/bin/hypr-eos-kill-yad-zombies"

    update_script="$HOME/.config/hypr-welcome/scripts/hypr_check_updates.sh"
    sudo ln -sf "$update_script" "/usr/bin/hypr_check_updates"

    # 2. Global Interactive Wallpaper Selector
    global_wallpaper_script="$HOME/.config/hypr/scripts/select-wallpaper"
    sudo ln -sf "$global_wallpaper_script" "/usr/bin/select-wallpaper"
    
    show_message "Symlinks created successfully!" "$GREEN"
fi

# ==============================================================================
# PART 3: NOTIFICATION & CLEANUP
# ==============================================================================
notify-send "Backup & Symlinks Complete" "Your dotfiles are backed up and symlinks are verified."
show_message "Script finished. Enjoy your Hyprland experience!" "$GREEN"
