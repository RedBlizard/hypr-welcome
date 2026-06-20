#!/bin/bash

# 1. Kill existing YAD instances (like the current hypr-welcome)
pkill -f yad

# 2. Define the removal script with some nice colors and verbose output
symlink_removal_script='
clear
echo -e "\033[1;34m=== SYMLINK REMOVAL SCRIPT (SAFE MODE) ===\033[0m"
echo ""
echo -e "\033[1;33mRemoving legacy symlinks...\033[0m"
echo ""

# -v stands for verbose, so you see exactly what is being removed
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

# 3. Launch kitty to run the removal script
# We use '--hold' so the terminal stays open until you press a key. 
# This gives you time to enter your sudo password and read the output.
alacritty --hold bash -c "$symlink_removal_script" &

# 4. Wait a moment to give the terminal time to open and prompt for sudo
sleep 2

# 5. Relaunch the welcome app
bash "$HOME/.config/hypr-welcome/scripts/hypr-welcome"
