#!/bin/bash

# Runs startup configurators once (flagged) per user session.
# Prevents re-running if the flag file already exists.

run_flagged() {
    local lock_file="$1"
    local job_name="$2"
    local job_cmd="$3"

    # Ensure the directory for the flag file exists
    mkdir -p "$(dirname "$lock_file")"

    # Check if the lock file already exists
    if [ -e "$lock_file" ]; then
        echo "$job_name has already run. Skipping."
        return 0   # Continue to the next task, do not exit the whole script
    fi

    echo "Starting $job_name..."
    
    # Check if the target script exists and is executable
    if [ -x "$job_cmd" ]; then
        # Voer het script uit en check direct of het succesvol was (exit code 0)
        if "$job_cmd"; then
            # Create the lock file ONLY after successful execution!
            touch "$lock_file"
            echo "$job_name completed successfully."
        else
            echo "⚠  Error: $job_cmd failed! Flag NOT set, will retry next session."
            return 1
        fi
    else
        echo "⚠  Warning: $job_cmd is not executable or does not exist!"
        return 1
    fi
}

# 1. Monitor workspaces configurator
run_flagged \
    "$HOME/.config/hypr/scripts/monitor_workspaces_flag" \
    "monitor_workspaces_configurator" \
    "$HOME/.config/hypr/scripts/monitor_workspaces_configurator.sh"
sleep 2

# 2. Waybar config switcher
run_flagged \
    "$HOME/.config/waybar/scripts/waybar_flag" \
    "yad_switch-waybar-config" \
    "$HOME/.config/hypr-welcome/scripts/yad_switch-waybar-config"
sleep 4

# 3. Hypr-welcome (now in its own dedicated config directory)
run_flagged \
    "$HOME/.config/hypr-welcome/scripts/welcome_flag" \
    "hypr-welcome" \
    "$HOME/.config/hypr-welcome/scripts/hypr-welcome"
