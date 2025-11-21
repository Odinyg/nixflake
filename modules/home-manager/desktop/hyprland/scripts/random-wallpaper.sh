#!/usr/bin/env bash

# Get random wallpaper from the wallpapers directory
WALLPAPER_DIR="$HOME/.config/wallpapers"

# Check if directory exists and has images
if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Find all image files (follow symlinks with -L) - use mapfile for efficiency
mapfile -t WALLPAPERS < <(find -L "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) 2>/dev/null)

# Check if any wallpapers were found
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No image files found in $WALLPAPER_DIR"
    exit 1
fi

# Select random wallpaper
RANDOM_WALLPAPER="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"

# Kill existing hyprpaper process
pkill hyprpaper

# Create temporary hyprpaper config with the random wallpaper (no quotes for hyprpaper)
cat > "$HOME/.config/hypr/hyprpaper-temp.conf" << EOF
preload = $RANDOM_WALLPAPER
wallpaper = ,$RANDOM_WALLPAPER
EOF

# Start hyprpaper with the new config
hyprpaper -c "$HOME/.config/hypr/hyprpaper-temp.conf" &

echo "Set wallpaper to: $RANDOM_WALLPAPER"