#!/bin/bash

# Store GPU information in a temporary file
gpu_info_file=$(mktemp)
lspci | grep -i vga > "$gpu_info_file"

# Display the information using yad in a text-info dialog
yad --title="GPU Information" \
    --text-info \
    --filename="$gpu_info_file" \
    --width=900 \
    --height=410 \
    --button="   You can just close me...:0"

# Remove the temporary file
rm "$gpu_info_file"
