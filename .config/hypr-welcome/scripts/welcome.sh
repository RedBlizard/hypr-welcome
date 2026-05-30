#!/bin/bash

# Runs startup configurators once (flagged) per user session.
# Prevents re-running if the flag file already exists.

run_flagged() {
    local lock_file="$1"
    local job_name="$2"
    local job_cmd="$3"

    mkdir -p "$(dirname "$lock_file")"

    if [ -e "$lock_file" ]; then
        echo "$job_name has already run. Skipping."
        return 0
    fi

    echo "Starting $job_name..."

    if [ -x "$job_cmd" ]; then
        if "$job_cmd"; then
            touch "$lock_file"
            echo "$job_name completed successfully."
        else
            echo "⚠ Error: $job_cmd failed! Flag NOT set, will retry next session."
            return 1
        fi
    else
        echo "⚠ Warning: $job_cmd is not executable or does not exist!"
        return 1
    fi
}

run_welcome() {
    local lock_file="$HOME/.config/hypr-welcome/scripts/welcome_flag"
    local job_cmd="$HOME/.config/hypr-welcome/scripts/hypr-welcome"

    mkdir -p "$(dirname "$lock_file")"

    if [ -e "$lock_file" ]; then
        echo "hypr-welcome has already run. Skipping."
        return 0
    fi

    echo "Starting hypr-welcome..."

    if [ ! -x "$job_cmd" ]; then
        echo "⚠ Warning: $job_cmd is not executable or does not exist!"
        return 1
    fi

    # Start hypr-welcome
    "$job_cmd"

    echo "Waiting for hypr-welcome window..."

    # Wait up to 10 seconds
    for i in {1..100}; do
        if hyprctl clients | grep -q "hypr-welcome"; then
            touch "$lock_file"
            echo "hypr-welcome window detected. Flag created."
            return 0
        fi

        sleep 0.1
    done

    echo "⚠ hypr-welcome window not detected. Flag NOT set."
    return 1
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

# 3. Hypr-welcome
run_welcome

exit 0
