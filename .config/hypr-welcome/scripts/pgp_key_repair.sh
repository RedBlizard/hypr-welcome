#!/bin/bash

# Function to repair PGP keys
repair_pgp_keys() {
    echo "Repairing PGP keys..."

    # Update the package databases first
    sudo pacman -Sy

    # Attempt to refresh the keyring
    sudo pacman-key --refresh-keys

    # If refreshing keys doesn't solve the issue, reinitialize the keyring
    if [ $? -ne 0 ]; then
        echo "Refreshing keys failed. Attempting to reinitialize the keyring..."

        # Remove the existing keyring directory
        sudo rm -r /etc/pacman.d/gnupg

        # Reinitialize the pacman keyring
        sudo pacman-key --init

        # Populate the keyring with the default keys
        sudo pacman-key --populate archlinux archlinux32 archlinuxarm endeavouros

        # Try updating again
        sudo pacman -Sy

        echo "Keyring reinitialized and PGP keys updated."
    else
        echo "PGP keys refreshed successfully."
    fi
}

# Main function to repair PGP keys
main() {
    echo "Launching a new Alacritty terminal to perform actions..."
    alacritty -e bash -c "$(declare -f repair_pgp_keys); repair_pgp_keys; echo 'Press any key to close...'; read -n1"
}

# Execute the main function
main

