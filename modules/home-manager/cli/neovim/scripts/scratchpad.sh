#!/usr/bin/env bash

# Scratchpad script that adds today's date if writing for the first time today

SCRATCHPAD_FILE="$HOME/Documents/Main/scratchpad.md"
TODAY=$(date +"%m-%d-%Y")
DATE_HEADER="# $TODAY"

# Create directories if they don't exist
mkdir -p "$(dirname "$SCRATCHPAD_FILE")"

# Create the file if it doesn't exist
if [[ ! -f "$SCRATCHPAD_FILE" ]]; then
    echo "$DATE_HEADER" > "$SCRATCHPAD_FILE"
    echo "" >> "$SCRATCHPAD_FILE"
else
    # Check if today's date is already in the file
    if ! grep -q "^# $TODAY" "$SCRATCHPAD_FILE"; then
        # Add today's date at the top
        {
            echo "$DATE_HEADER"
            echo ""
            cat "$SCRATCHPAD_FILE"
        } > /tmp/scratchpad_temp && mv /tmp/scratchpad_temp "$SCRATCHPAD_FILE"
    fi
fi

# Open the file in neovim and position cursor after the date
nvim "+/^# $TODAY" "+normal! o" "$SCRATCHPAD_FILE"