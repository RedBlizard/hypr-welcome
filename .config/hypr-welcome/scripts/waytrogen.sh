#!/bin/bash

# Step 1: Start waytrogen
hyprctl dispatch exec "[workspace 8] waytrogen"

# Store the PID of waytrogen
waytrogen_pid=$!

# Step 2: Kill yad (hypr-welcome)
pkill -f yad

# Step 3: Check if waytrogen is closed
while kill -0 $waytrogen_pid 2>/dev/null; do
    sleep 1
done

# Step 4: Restart hypr-welcome
hypr-welcome &
