#!/bin/bash
# ----------------------------
# GENERIC RUN-ONCE FUNCTION (MULTIPLE FLAGS SUPPORT)
# ----------------------------
run_flagged() {
    local job_name="$1"
    local job_cmd="$2"
    shift 2
    local lock_files=("$@")

    # Create directories for all flags
    for lock_file in "${lock_files[@]}"; do
        mkdir -p "$(dirname "$lock_file")"
    done

    # Check if ALL flags exist (if so, the job has already run)
    local all_exist=true
    for lock_file in "${lock_files[@]}"; do
        if [ ! -e "$lock_file" ]; then
            all_exist=false
            break
        fi
    done

    if [ "$all_exist" = true ]; then
        echo "$job_name has already run. Skipping."
        return 0
    fi

    echo "Starting $job_name..."

    if [ -x "$job_cmd" ]; then
        if "$job_cmd"; then
            for lock_file in "${lock_files[@]}"; do
                touch "$lock_file"
            done
            echo "$job_name completed successfully, all flags placed."
        else
            echo "⚠ Error: $job_cmd failed! No flags placed."
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
    local lock_file="$HOME/.cache/run_once_flags/welcome_flag"
    local job_cmd="$HOME/.config/hypr-welcome/scripts/hypr-welcome"

    mkdir -p "$(dirname "$lock_file")"

    if [ -e "$lock_file" ]; then
        echo "hypr-welcome already done."
        return 0
    fi

    echo "Starting hypr-welcome..."
    "$job_cmd" &
    local job_pid=$!

    # Wait until the window actually appears (max 10 seconds)
    for i in {1..100}; do
        if hyprctl clients | grep -q "hypr-welcome"; then
            echo "hypr-welcome window detected"
            break
        fi
        sleep 0.1
    done

    # Wait until the process ends OR the window disappears
    while kill -0 "$job_pid" 2>/dev/null || hyprctl clients | grep -q "hypr-welcome"; do
        sleep 1
    done

    touch "$lock_file"
    echo "hypr-welcome finished and closed, flag placed."
}

# ----------------------------
# WAYBAR SWITCHER
# ----------------------------
run_waybar_switcher() {
    local lock_file="$HOME/.cache/run_once_flags/waybar_flag"
    mkdir -p "$(dirname "$lock_file")"

    if [ -e "$lock_file" ]; then
        echo "Waybar already configured. Skipping."
        return 0
    fi

    echo "Waybar not yet configured — waiting for user to pick via hypr-welcome."
}

# ==========================================
# EXECUTION ON STARTUP
# ==========================================

# 1. Monitor workspaces configurator
run_flagged \
    "monitor_workspaces_configurator" \
    "$HOME/.config/hypr/scripts/monitor_workspaces_configurator.sh" \
    "$HOME/.cache/run_once_flags/monitor_workspaces_flag"

sleep 2

# 2. WAYBAR SWITCHER CHECK
run_waybar_switcher

sleep 4

# 3. HYPR WELCOME
run_welcome

exit 0
