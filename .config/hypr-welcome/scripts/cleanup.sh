#!/bin/bash

pkill -f yad

# Launch kitty terminal safely
launch_kitty() {
    kitty bash -c "$1"
}

# Safe debug package removal
remove_debug_packages() {
    debug_packages=$(pacman -Qq | grep '\-debug$')

    if [ -n "$debug_packages" ]; then
        echo "Removing debug packages:"
        echo "$debug_packages"

        for package in $debug_packages; do
            sudo pacman -Rs --noconfirm "$package"
        done

        echo "Debug packages removed."
    else
        echo "No debug packages found."
    fi
}

# Orphan cleanup (optional but useful)
remove_orphans() {
    orphans=$(pacman -Qtdq)

    if [ -n "$orphans" ]; then
        echo "Removing orphan packages:"
        echo "$orphans"
        sudo pacman -Rns --noconfirm $orphans
    else
        echo "No orphan packages found."
    fi
}

# Main cleanup script (safe Arch version)
cleanup_script='
echo "=== PACMAN CACHE CLEANUP (SAFE MODE) ==="

# Safer alternative to -Scc
echo "Cleaning package cache (keeping installed versions)..."
sudo pacman -Sc --noconfirm

# Modern cache cleanup tool (if available)
if command -v paccache >/dev/null 2>&1; then
    echo "Running paccache cleanup..."
    sudo paccache -r
else
    echo "paccache not found, skipping advanced cleanup."
fi

echo ""
echo "=== YAY CACHE CLEANUP ==="
if command -v yay >/dev/null 2>&1; then
    yay -Sc --noconfirm
else
    echo "yay not installed, skipping..."
fi

echo ""
echo "=== DEBUG PACKAGES ==="
'"$(declare -f remove_debug_packages)"'
remove_debug_packages

echo ""
echo "=== ORPHAN PACKAGES ==="
'"$(declare -f remove_orphans)"'
remove_orphans

echo ""
echo "DONE ✔"
'

# Run in kitty
launch_kitty "
$cleanup_script
"

# Relaunch welcome app
sleep 2
bash "$HOME/.config/hypr-welcome/scripts/hypr-welcome"
