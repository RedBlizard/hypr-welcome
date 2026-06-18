#!/bin/bash
# Directory for wallpapers
DIR="$HOME/Pictures/wallpapers-redblizard/"
CACHE_DIR="$HOME/.cache/awww"
CURRENT_CACHE="$CACHE_DIR/current_wallpaper.png"

# Wofi configuration paths for the wallpaper picker
WOFI_CONFIG="$HOME/.config/wofi/dmenu-launcher/config"
WOFI_STYLE="$HOME/.config/wofi/dmenu-launcher/style.css"

mkdir -p "$CACHE_DIR"

# 1. Stop the random wallpaper loop if it's running in the background
if pgrep -f "random-wallpaper" >/dev/null; then
    pkill -f "random-wallpaper"
    echo "Stopped random-wallpaper loop at $(date)" >> "$CACHE_DIR/no_wallpaper_loop.log"
fi

# 2. Stop existing awww-daemon if it's running
if pgrep -x awww-daemon >/dev/null; then
    pkill -x awww-daemon
    echo "Stopped awww-daemon at $(date)" >> "$CACHE_DIR/no_wallpaper_loop.log"
    sleep 0.5 # Give the daemon a moment to cleanly release resources
fi

# 3. Start awww-daemon fresh
echo "Starting awww-daemon at $(date)" >> "$CACHE_DIR/no_wallpaper_loop.log"
awww-daemon & disown

set_wallpaper() {
    local img="$1"
    # Change wallpaper using awww with transition effects
    awww img "$img" --transition-step 20 --transition-fps=20
    # Copy the selected wallpaper to cache for other tools (waybar, hyprlock, hypr-welcome)
    cp "$img" "$CURRENT_CACHE"
}

select_wp() {
    # Wofi requires the specific 'img:<path>:text:<name>' syntax for dmenu icons
    CHOICE=$(find "${DIR}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" \) | sort | while IFS= read -r f; do
        printf 'img:%s:text: \n' "$f"
    done | wofi --show dmenu \
                 --conf "$WOFI_CONFIG" \
                 --style "$WOFI_STYLE" \
                 --prompt "Select Wallpaper" \
                 --cache-file /dev/null)

    [ -z "$CHOICE" ] && exit 0

    FULLPATH=$(echo "$CHOICE" | sed 's/^img:\(.*\):text:.*$/\1/')

    if [ -f "$FULLPATH" ]; then
        set_wallpaper "$FULLPATH"
    fi
}

# --- Main Execution Flow ---

# Step 1: Kill yad (hypr-welcome) so it clears the screen for wofi
pkill -f yad
sleep 0.2 # Give it a fraction of a second to cleanly close

# Step 2: Launch the selector in the background
# The '&' is crucial here, otherwise the script pauses and $! won't capture the PID
select_wp &
SELECTOR_PID=$!

# Step 3: Wait for wofi (the selector function) to close
# 'wait' is the native, clean bash way to pause until a background PID finishes
wait $SELECTOR_PID

# Step 4: Restart hypr-welcome (it will now read the newly updated cache!)
hypr-welcome & disown
