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
    
    # Check if the repo directory actually exists (prevents errors on fresh installs)
    if [ ! -d "$repo_dir/.git" ]; then
        echo "Repo not found or not a git directory: $repo_dir" >&2
        return 1
    fi
    
    # Use a SUBSHELL ( ... ) so the 'cd' doesn't leak into the main daemon shell!
    (
        cd "$repo_dir" || exit 1
        
        # 5 sec timeout + quiet + hide errors -> Daemon stays responsive and logs stay clean
        # (Slightly longer timeout than the GUI since this runs silently in the background)
        if ! timeout 5 git fetch origin main --quiet 2>/dev/null; then
            exit 1
        fi
        
        local commits_behind
        commits_behind=$(git rev-list --count HEAD..origin/main 2>/dev/null)
        
        if [ "${commits_behind:-0}" -gt 0 ]; then
            exit 0  # Updates available
        else
            exit 1  # No updates
        fi
    )
}

# Array of repositories and their respective update scripts
repos=(
    "Hyprland-blizz:$HOME/hyprland-dots/Hyprland-blizz:$HOME/.config/hypr-welcome/scripts/hypr_blizz_update.sh"
    "hypr-welcome:$HOME/hyprland-dots/hypr-welcome:$HOME/.config/hypr-welcome/scripts/hypr_welcome_update.sh"
    "hypr-waybar:$HOME/hyprland-dots/hypr-waybar:$HOME/.config/hypr-welcome/scripts/hypr_waybar_update.sh"
)

# Function to handle notifications for a specific repository
handle_repository_updates() {
    local repo_name="$1"
    local repo_dir="$2"
    local update_script="$3"
    
    # Initial critical notifications loop
    for (( i=1; i<=2; i++ )); do
        if check_updates "$repo_dir"; then
            echo "Updates found in $repo_name"
            send_notification "$repo_name" "critical"
        else
            echo "No updates found in $repo_name"
        fi
        # Wait for 3 minutes
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

# Loop through each repository and start update notifications in the background
for repo_info in "${repos[@]}"; do
    IFS=':' read -r -a repo <<< "$repo_info"
    repo_name="${repo[0]}"
    repo_dir="${repo[1]}"
    update_script="${repo[2]}"
    
    handle_repository_updates "$repo_name" "$repo_dir" "$update_script" &
done

# Trap to clean up zombie processes when the daemon is killed
trap "pkill -P $$" EXIT

# Wait for all background processes to finish
wait
