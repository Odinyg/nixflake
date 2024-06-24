#!/bin/bash
swayidle -w \
timeout 600 ' swaylock ' \
timeout 630 ' hyprctl dispatch dpms off' \
timeout 6000 'systemctl suspend' \
resume ' hyprctl dispatch dpms on' \
before-sleep 'swaylock'
