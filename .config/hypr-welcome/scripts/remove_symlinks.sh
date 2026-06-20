#!/bin/bash

# 1. Kill existing YAD instances (like the current hypr-welcome)
pkill -f yad

# 2. Define the removal script
symlink_removal_script='
clear
echo -e "\033[1;34m=== SYMLINK REMOVAL SCRIPT (SAFE MODE) ===\033[0m"
echo ""
echo -e "\033[1;33mRemoving legacy symlinks...\033[0m"
echo ""

sudo rm -fv /usr/bin/hypr-welcome
sudo rm -fv /usr/bin/hypr-eos-kill-yad-zombies
sudo rm -fv /usr/bin/hypr_check_updates
sudo rm -fv /usr/bin/select-wallpaper

echo ""
echo -e "\033[1;32mDone. Legacy symlinks removed successfully.\033[0m"
echo ""
echo "Press any key to close this terminal..."
read -n 1 -s
'

# 3. Wacht tot Alacritty terminal gesloten wordt (geen & = blocking)
alacritty -e bash -c "$symlink_removal_script"

# 4. Direct herlanceren zodra terminal dicht gaat
bash "$HOME/.config/hypr-welcome/scripts/hypr-welcome"
