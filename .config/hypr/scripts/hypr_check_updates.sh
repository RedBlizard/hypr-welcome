#!/bin/bash

# Function to send a notification using notify-send (compatible with swaync)
send_notification() {
    local repo_name="$1"
    local urgency="$2"

    local formatted_message=""

    if [ "$urgency" = "critical" ]; then
        formatted_message="Critical update!
There are updates available for $repo_name.
Run the hypr-welcome app and update."
    elif [ "$urgency" = "normal" ]; then
        formatted_message="Update reminder!
There are updates available for $repo_name.
Please run the hypr-welcome app and update."
    else
        formatted_message="$repo_name: $3"  # Default message for other urgency levels
    fi

    notify-send --urgency="$urgency" "Hyprland Updates" "$formatted_message"
}

# Function to check for updates in a specific repository
check_updates() {
    local repo_dir="$1"
    cd "$repo_dir" || { echo "Failed to change to $repo_dir directory." >&2; return 1; }
    echo "Checking updates in $(pwd)"
    git fetch origin main
    local commits_behind=$(git rev-list --count HEAD..origin/main)
    echo "Commits behind: $commits_behind"
    if [ "$commits_behind" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Array of repositories and their respective update scripts
repos=(
    "Hyprland-blizz:$HOME/hyprland-dots/Hyprland-blizz:$HOME/.config/hypr/scripts/hypr_blizz_update.sh"
    "hypr-welcome:$HOME/hyprland-dots/hypr-welcome:$HOME/.config/hypr/scripts/hypr_welcome_update.sh"
    "hypr-waybar:$HOME/hyprland-dots/hypr-waybar:$HOME/.config/hypr/scripts/hypr_waybar_update.sh"
)

# Function to handle notifications for a specific repository
handle_repository_updates() {
    local repo_name="$1"
    local repo_dir="$2"
    local update_script="$3"

    for (( i=1; i<=2; i++ )); do
        if check_updates "$repo_dir"; then
            echo "Updates found in $repo_name"
            send_notification "$repo_name" "critical"
        else
            echo "No updates found in $repo_name"
        fi
        # Wait for 1 minute
        sleep 180
    done

    # Additional critical notification after 5 minutes
    sleep 300
    if check_updates "$repo_dir"; then
        echo "Additional updates found in $repo_name"
        send_notification "$repo_name" "critical"
    fi

    # Regular notification loop with normal priority, only if critical notifications were ignored
    sleep 900  # First reminder after 15 minutes
    while true; do
        if check_updates "$repo_dir"; then
            echo "Regular updates found in $repo_name"
            send_notification "$repo_name" "normal"
        fi
        # Subsequent reminders every 30 minutes
        sleep 1800
    done
}

# Loop through each repository and start update notifications
for repo_info in "${repos[@]}"; do
    IFS=':' read -r -a repo <<< "$repo_info"
    repo_name="${repo[0]}"
    repo_dir="${repo[1]}"
    update_script="${repo[2]}"
    
    handle_repository_updates "$repo_name" "$repo_dir" "$update_script" &
done

# Trap to clean up zombie processes
trap "pkill -P $$" EXIT

# Wait for all background processes to finish
wait
