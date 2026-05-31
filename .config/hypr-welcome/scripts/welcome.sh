#!/bin/bash
# Runs startup configurators once (flagged) per user session.
# Prevents re-running if the flag file already exists.

run_flagged() {
    local lock_file="$1"
    local job_name="$2"
    local job_cmd="$3"

    # Ensure the directory for the flag file exists
    # This fixes the issue when hypr-welcome/scripts/ doesn't exist yet
    mkdir -p "$(dirname "$lock_file")"

    # Check if the lock file already exists
    if [ -e "$lock_file" ]; then
        echo "$job_name has already run. Skipping."
        return 0   # Continue to the next task, do not exit the whole script
    fi

    echo "Starting $job_name..."

    # Check if the target script exists and is executable
    if [ -x "$job_cmd" ]; then
        "$job_cmd"
    else
        echo "⚠  Warning: $job_cmd is not executable or does not exist!"
        return 1
    fi

    # Create the lock file
    touch "$lock_file"
    echo "$job_name completed successfully."
}

# 1. Monitor workspaces configurator
run_flagged \
    "$HOME/.config/hypr/scripts/monitor_workspaces_flag" \
    "monitor_workspaces_configurator" \
    "$HOME/.config/hypr/scripts/monitor_workspaces_configurator.sh"

sleep 2

# 2. Waybar config switcher
run_flagged \
    "$HOME/.config/hypr/scripts/monitor_workspaces_flag" \
    "monitor_workspaces_configurator" \
    "$HOME/.config/hypr/scripts/monitor_workspaces_configurator.sh"

sleep 4

# 3. Hypr-welcome (now in its own dedicated config directory)
# mkdir -p inside run_flagged ensures ~/.config/hypr-welcome/scripts/ exists
# ----------------------------
# HYPR WELCOME
# ----------------------------
run_welcome() {
    local lock_file="$HOME/.config/hypr-welcome/scripts/welcome_flag"
    local job_cmd="$HOME/.config/hypr-welcome/scripts/hypr-welcome"
 
    mkdir -p "$(dirname "$lock_file")"
 
    if [ -e "$lock_file" ]; then
        echo "hypr-welcome already done."
        return 0
    fi
 
    "$job_cmd"
 
    for i in {1..100}; do
        if hyprctl clients | grep -q "hypr-welcome"; then
            touch "$lock_file"
            echo "hypr-welcome ready"
            return 0
        fi
        sleep 0.1
    done
 
    echo "hypr-welcome not detected"
}
    
# ----------------------------
# 4. HYPR WELCOME
# ----------------------------
run_welcome
 
exit 0    
