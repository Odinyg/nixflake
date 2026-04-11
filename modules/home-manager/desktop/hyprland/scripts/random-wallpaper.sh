#!/usr/bin/env bash

# Rotate wallpaper — writes hyprpaper v0.8.x config, restarts the systemd
# service, and copies to ~/.config/current-wallpaper.png for swaylock.

WALLPAPER_DIR="$HOME/.config/wallpapers"
CURRENT="$HOME/.config/current-wallpaper.png"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

WALLPAPERS=($(find -L "$WALLPAPER_DIR" -type f -iname "*.png" 2>/dev/null))

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

PICK="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"

cp -f "$PICK" "$CURRENT"

# Remove Nix-managed symlink if present so we can write a real file
[ -L "$HYPRPAPER_CONF" ] && rm -f "$HYPRPAPER_CONF"

VERSION=$(hyprpaper --version 2>&1 | grep -oP 'v\K[0-9]+\.[0-9]+')
if [ "$(echo "$VERSION >= 0.8" | bc 2>/dev/null)" = "1" ]; then
    cat > "$HYPRPAPER_CONF" << EOF
preload = $PICK

wallpaper {
    monitor = *
    path = $PICK
}
EOF
else
    cat > "$HYPRPAPER_CONF" << EOF
preload = $PICK
wallpaper = ,$PICK
EOF
fi

systemctl --user restart hyprpaper.service 2>/dev/null || {
    pkill hyprpaper 2>/dev/null
    sleep 0.3
    hyprpaper -c "$HYPRPAPER_CONF" &
    disown
}

echo "Wallpaper set to: $(basename "$PICK")"
