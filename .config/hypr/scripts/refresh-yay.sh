#!/bin/bash

# Function to check if Yay is installed
check_yay_installed() {
    if ! command -v yay &>/dev/null; then
        echo "Yay is not installed. Installing Yay..."
        install_yay
    else
        echo "Yay is already installed."
    fi
}

# Function to install Yay
install_yay() {
    sudo pacman -S --needed yay
}

# Function to repair Yay
repair_yay() {
    echo "Repairing Yay..."

    # Rebuild Yay package only
    yay -S yay --noconfirm

    # Check if Yay was successfully repaired
    if command -v yay &>/dev/null; then
        echo "Yay has been successfully repaired."
    else
        echo "Failed to repair Yay. Please check your system."
    fi
}

# Main function to check and repair Yay
main() {
    echo "Launching a new Alacritty terminal to perform actions..."
    alacritty -e bash -c "$(declare -f check_yay_installed); $(declare -f install_yay); $(declare -f repair_yay); check_yay_installed; repair_yay; echo 'Press any key to close...'; read -n1"
}

# Execute the main function
main
