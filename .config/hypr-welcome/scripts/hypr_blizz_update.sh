#!/bin/bash

# Define color codes
RED='\033[0;31m'
BLUE='\033[1;34m'
GREEN='\033[38;2;149;209;137m'
NC='\033[0m' # No Color

# Function to launch an Alacritty terminal if not already launched
launch_alacritty_terminal() {
    if [ -z "$ALACRITTY_WINDOW_ID" ]; then
        if ! alacritty -e "$0" &>/dev/null; then
            echo "Failed to launch Alacritty. Please check your Alacritty installation or configuration."
            exit 1
        fi
        exit
    fi
}

# Call the function to launch Alacritty terminal
launch_alacritty_terminal

# Set the log file path
log_file="$HOME/hyprland-update_log.txt"

# Redirect stdout (1) and stderr (2) to the log file
exec > >(tee -i "$log_file") 2>&1

# Making a backup of main configs in .config
username=$(whoami)
echo "Now we are making a backup of existing configurations!"
echo

backup_dir="/home/$username/.config/backup"
mkdir -p "$backup_dir"

backup() {
    local source_dir="$1"
    local dest_dir="$2"
    mkdir -p "$dest_dir"
    cp -r "$source_dir" "$dest_dir"
}

folders=("alacritty" "btop" "cava" "dunst" "hypr" "kitty" "Kvantum" "networkmanager-dmenu" "nwg-look" "pacseek" "pipewire" "qt6ct" "ranger" "sddm-config-editor" "systemd" "Thunar" "waybar" "wlogout" "wofi" "xsettingsd" "gtk-2.0" "gtk-3.0" "gtk-4.0" "starship" "swaync")

for folder in "${folders[@]}"; do
    folder_path="/home/$username/.config/$folder"
    backup_path="$backup_dir/$folder"
    if [ -d "$folder_path" ]; then
        backup "$folder_path" "$backup_path"
    else
        mkdir -p "$folder_path"
        backup "$folder_path" "$backup_path"
    fi
done

# Ensure the hyprland-dots directory exists
DOTFILES_DIR="$HOME/hyprland-dots"
mkdir -p "$DOTFILES_DIR"

# Repositories to clone
REPOS=(
    "https://github.com/RedBlizard/Hyprland-blizz.git"
)

# Set GIT_DISCOVERY_ACROSS_FILESYSTEM if needed
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Banner
show_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}"
}

show_message "░█─░█ █──█ █▀▀█ █▀▀█ █── █▀▀█ █▀▀▄ █▀▀▄ 　 █──█ █▀▀█ █▀▀▄ █▀▀█ ▀▀█▀▀ █▀▀" "$RED"
show_message "░█▀▀█ █▄▄█ █──█ █▄▄▀ █── █▄▄█ █──█ █──█ 　 █──█ █──█ █──█ █▄▄█ ──█── █▀▀" "$RED"
show_message "░█─░█ ▄▄▄█ █▀▀▀ ▀─▀▀ ▀▀▀ ▀──▀ ▀──▀ ▀▀▀─ 　 ▀▀▀▀ █▀▀▀ ▀▀▀─ ▀──▀ ──▀── ▀▀▀" "$RED"
echo

# Clone or update the repositories
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_dir="$DOTFILES_DIR/$repo_name"

    if [ ! -d "$repo_dir" ]; then
        show_message "Cloning $repo_name repository..." "$BLUE"
        git clone "$repo" "$repo_dir" || { show_message "Failed to clone $repo_name repository." "$RED"; exit 1; }
    else
        cd "$repo_dir" || { show_message "Failed to change to directory $repo_dir." "$RED"; exit 1; }
        show_message "Pulling the latest changes from the $repo_name repository..." "$BLUE"
        if ! git pull origin main; then
            show_message "Failed to pull $repo_name repository." "$RED"
            exit 1
        fi
    fi
done

# Check for updates in each repository
updates_available=false
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    repo_dir="$DOTFILES_DIR/$repo_name"

    if cd "$repo_dir" && git fetch origin main && [ "$(git rev-list --count HEAD..origin/main)" -gt 0 ]; then
        updates_available=true
        show_message "Updates are available for $repo_name repository." "$BLUE"
    fi
done

if [ "$updates_available" = true ]; then
    show_message "Updates are available for one or more repositories." "$BLUE"
else
    show_message "No updates available for the repositories." "$BLUE"
fi

read -rp "Do you want to update your dotfiles? (Enter 'Yy' for yes or 'Nn' for no): (Yy/Nn): " update_choice

if [[ "$update_choice" =~ ^[Yy]$ ]]; then
    # SAFE: Sync ONLY specific subdirectories from Hyprland-blizz
    # NEVER sync entire $HOME or .config with --delete!
    show_message "Updating dotfiles from Hyprland-blizz..." "$BLUE"

    # Sync hidden directories (these are fully managed by the repo)
    rsync -a --delete "$HOME/hyprland-dots/Hyprland-blizz/.icons/" "$HOME/.icons/" \
        || { show_message "Failed to update .icons from Hyprland-blizz." "$RED"; exit 1; }

    rsync -a --delete "$HOME/hyprland-dots/Hyprland-blizz/.Kvantum-themes/" "$HOME/.Kvantum-themes/" \
        || { show_message "Failed to update .Kvantum-themes from Hyprland-blizz." "$RED"; exit 1; }

    rsync -a "$HOME/hyprland-dots/Hyprland-blizz/.local/" "$HOME/.local/" \
        || { show_message "Failed to update .local from Hyprland-blizz." "$RED"; exit 1; }

    # Sync Pictures directory (no --delete: user files like screenshots must be preserved)
    rsync -a "$HOME/hyprland-dots/Hyprland-blizz/Pictures/" "$HOME/Pictures/" \
        || { show_message "Failed to update Pictures from Hyprland-blizz." "$RED"; exit 1; }

    # Sync .config subdirectories (ONLY the ones managed by this repo)
    for config_dir in alacritty btop cava dunst hypr kitty Kvantum networkmanager-dmenu nwg-look pacseek pipewire qt6ct ranger sddm-config-editor systemd Thunar waybar wlogout wofi xsettingsd gtk-2.0 gtk-3.0 gtk-4.0 starship swaync; do
        if [ -d "$HOME/hyprland-dots/Hyprland-blizz/.config/$config_dir" ]; then
            rsync -a --delete "$HOME/hyprland-dots/Hyprland-blizz/.config/$config_dir/" "$HOME/.config/$config_dir/" \
                || { show_message "Failed to update $config_dir from Hyprland-blizz." "$RED"; exit 1; }
        fi
    done
    # ============================================================
    # Place session flags (hypr only — waybar and hypr-welcome excluded)
    # Flags from welcome.sh:
    #   - monitor_workspaces_configurator
    # Flags from monitor_workspaces_configurator.sh:
    #   - first-time execution
    #   - one-time execution
    # ============================================================
    show_message "Placing session flags (hypr only)..." "$BLUE"

    declare -a FLAGS=(
        "$HOME/.cache/run_once_flags/monitor_workspaces_flag"
        "$HOME/.cache/run_once_flags/execution_flag"
        "$HOME/.cache/run_once_flags/execution_once_flag"
    )

    for flag in "${FLAGS[@]}"; do
        mkdir -p "$(dirname "$flag")"
        touch "$flag" && show_message "  ✔ Placed: $flag" "$GREEN" \
            || show_message "  ✖ Failed to place: $flag" "$RED"
    done

    show_message "Hypr flags placed. Waybar and hypr-welcome configurators are unaffected." "$GREEN"

else
    show_message "No hyprland dotfiles update performed." "$BLUE"
    exit 0
fi

# Enable hypridle.service if not already enabled
if ! systemctl --user is-enabled hypridle.service >/dev/null 2>&1; then
    systemctl --user enable --now hypridle.service
fi

# Change to the home directory
cd "$HOME" || { echo 'Failed to change directory to home directory.'; exit 1; }

# Cleanup
rm -rf $HOME/README.md
rm -rf $HOME/sddm-images
rm -rf $HOME/LICENSE
rm -rf $HOME/sddm.conf

# Change to the scripts directory
cd "$HOME/.config/hypr-welcome/scripts" || { echo "Failed to change to the scripts directory." >&2; exit 1; }

# Function to check if all required symlinks exist
check_symlinks() {
    local symlinks=("hypr-welcome" "hypr-eos-kill-yad-zombies" "hypr_check_updates")
    local all_exist=true
    
    for symlink in "${symlinks[@]}"; do
        if [ ! -L "/usr/bin/$symlink" ]; then
            all_exist=false
            break
        fi
    done
    
    if $all_exist; then
        echo "All required symlinks exist."
        return 0
    else
        echo "Some symlinks are missing."
        return 1
    fi
}

# Check if the symlinks exist
if ! check_symlinks; then
    echo "Creating missing symlinks..."
    
    # Change to the scripts directory
    cd "$HOME/.config/hypr-welcome/scripts" || { echo "Failed to change to the scripts directory." >&2; exit 1; }

    # Path to your welcome script
    welcome_script="$HOME/.config/hypr-welcome/scripts/hypr-welcome"

    # Path to the symlink in /usr/bin
    symlink="/usr/bin/hypr-welcome"

    # Create new symlink
    sudo ln -sf "$welcome_script" "$symlink"

    # Path to your kill script
    kill_script="$HOME/.config/hypr-welcome/scripts/hypr-eos-kill-yad-zombies"

    # Path to the symlink in /usr/bin
    symlink="/usr/bin/hypr-eos-kill-yad-zombies"

    # Create new symlink
    sudo ln -sf "$kill_script" "$symlink"

    # Path to your update script
    update_script="$HOME/.config/hypr-welcome/scripts/hypr_check_updates.sh"

    # Path to the symlink in /usr/bin
    symlink="/usr/bin/hypr_check_updates"

    # Create new symlink
    sudo ln -sf "$update_script" "$symlink"
fi


# Notify user about the end of the script
notify-send "We are done. Enjoy your updated Hyprland experience."
