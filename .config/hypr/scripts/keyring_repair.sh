#!/bin/bash

# Function to initialize and refresh the Arch Linux keyring
repair_arch_keyring() {
    echo "Repairing the Arch Linux keyring..."

    # Refresh the keyring
    sudo pacman -Sy archlinux-keyring

    # If the keyring update fails, try refreshing it manually
    if [ $? -ne 0 ]; then
        echo "Keyring update failed. Attempting manual keyring refresh..."
        sudo rm -r /etc/pacman.d/gnupg
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
    fi

    echo "Arch Linux keyring repair complete."
}

# Function to initialize and refresh the EndeavourOS keyring
repair_endeavouros_keyring() {
    echo "Repairing the EndeavourOS keyring..."

    # Refresh the EndeavourOS keyring
    sudo pacman -Sy endeavouros-keyring

    # If the keyring update fails, try reinstalling it
    if [ $? -ne 0 ]; then
        echo "EndeavourOS keyring update failed. Reinstalling the keyring..."
        sudo pacman -S --noconfirm endeavouros-keyring
    fi

    echo "EndeavourOS keyring repair complete."
}

# Main function to repair both keyrings
main() {
    echo "Launching a new Alacritty terminal to perform actions..."
    alacritty -e bash -c "$(declare -f repair_arch_keyring); $(declare -f repair_endeavouros_keyring); repair_arch_keyring; repair_endeavouros_keyring; echo 'Press any key to close...'; read -n1"
}

# Execute the main function
main
