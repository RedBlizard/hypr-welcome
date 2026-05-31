#!/bin/bash

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
            echo "⚠ Error: $job_cmd failed!"
            return 1
        fi
    else
        echo "⚠ Warning: $job_cmd not executable or missing!"
        return 1
    fi
}

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
# 1. Monitor workspaces configurator
# ----------------------------
run_flagged \
    "$HOME/.config/hypr/scripts/monitor_workspaces_flag" \
    "monitor_workspaces_configurator" \
    "$HOME/.config/hypr/scripts/monitor_workspaces_configurator.sh"

sleep 6

# ----------------------------
# 2. HYPR WELCOME
# ----------------------------
run_welcome

exit 0
