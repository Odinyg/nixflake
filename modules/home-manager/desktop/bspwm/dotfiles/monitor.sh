#!/bin/bash

# Check if the hostname is VNPC-21
if [[ "$(hostname)" == "VNPC-21" ]]; then
    # Check if HDMI-1 is connected
    if xrandr | grep -q "HDMI-1 connected"; then
        autorandr docked
    else
        autorandr mobile
    fi
fi

