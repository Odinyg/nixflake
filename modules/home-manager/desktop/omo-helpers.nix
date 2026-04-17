{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.omo-helpers;
in
{
  options.omo-helpers.enable = lib.mkEnableOption "Omarchy-style desktop UX helpers (station testbed)";
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        hyprpicker
        rofi-emoji
        wtype
        cliphist
        wl-clipboard
        libnotify
        procps
        jq
        desktop-file-utils
        (writeShellScriptBin "omo-launch-or-focus" ''
          set -eu
          CLASS_RE="''${1:?usage: omo-launch-or-focus <class-regex> <cmd...>}"
          shift
          ADDR=$(${pkgs-unstable.hyprland}/bin/hyprctl clients -j \
            | ${pkgs.jq}/bin/jq -r --arg re "$CLASS_RE" \
              '[.[] | select((.class // "") | test($re; "i"))] | .[0].address // empty')
          if [ -n "''${ADDR:-}" ]; then
            ${pkgs-unstable.hyprland}/bin/hyprctl dispatch focuswindow "address:$ADDR"
          else
            exec "$@"
          fi
        '')
        (writeShellScriptBin "omo-webapp-install" ''
          set -eu
          NAME="''${1:?usage: omo-webapp-install <Name> <URL>}"
          URL="''${2:?usage: omo-webapp-install <Name> <URL>}"
          APPDIR="''${XDG_DATA_HOME:-$HOME/.local/share}/applications"
          SLUG=$(printf '%s' "$NAME" | tr ' ' '-')
          FILE="$APPDIR/omo-webapp-''${SLUG}.desktop"
          mkdir -p "$APPDIR"
          cat > "$FILE" <<EOF
          [Desktop Entry]
          Type=Application
          Name=$NAME
          Exec=zen-beta --new-window $URL
          Icon=zen-beta
          Categories=Network;WebBrowser;
          StartupWMClass=$NAME
          NoDisplay=false
          EOF
          ${pkgs.desktop-file-utils}/bin/desktop-file-validate "$FILE" \
            || { ${pkgs.libnotify}/bin/notify-send "omo-webapp-install" "Invalid desktop file" -t 3000; exit 1; }
          ${pkgs.libnotify}/bin/notify-send "Web App Installed" "$NAME" -t 3000
        '')
        (writeShellScriptBin "omo-window-pop" ''
          set -eu
          HC=${pkgs-unstable.hyprland}/bin/hyprctl
          JQ=${pkgs.jq}/bin/jq
          ACT=$($HC activewindow -j)
          FLOATING=$(printf '%s' "$ACT" | $JQ -r '.floating')
          PINNED=$(printf '%s' "$ACT" | $JQ -r '.pinned')
          FULLSCREEN=$(printf '%s' "$ACT" | $JQ -r '.fullscreen')
          MON=$(printf '%s' "$ACT" | $JQ -r '.monitor')
          RES=$($HC monitors -j | $JQ -r --argjson m "$MON" '.[] | select(.id == $m) | "\(.width)x\(.height)"')
          W=$(printf '%s' "$RES" | cut -dx -f1)
          H=$(printf '%s' "$RES" | cut -dx -f2)
          TW=$((W * 75 / 100))
          TH=$((H * 75 / 100))
          if [ "$FULLSCREEN" != "0" ] && [ "$FULLSCREEN" != "null" ] && [ "$FULLSCREEN" != "false" ]; then
            $HC dispatch fullscreen 0
          fi
          if [ "$FLOATING" = "true" ] && [ "$PINNED" = "true" ]; then
            $HC dispatch pin; $HC dispatch togglefloating; exit 0
          fi
          [ "$FLOATING" = "false" ] && $HC dispatch togglefloating
          $HC dispatch resizeactive exact "$TW" "$TH"
          $HC dispatch centerwindow
          $HC dispatch pin
        '')
        (writeShellScriptBin "omo-clipboard-pick" ''
          set -eu
          ${pkgs.procps}/bin/pkill -x rofi || true
          PICK=$(${pkgs.cliphist}/bin/cliphist list \
            | ${pkgs.rofi}/bin/rofi -dmenu -p "Clipboard" -theme-str 'window { width: 50%; }')
          [ -n "''${PICK:-}" ] \
            && printf '%s' "$PICK" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
        '')
        (writeShellScriptBin "omo-emoji-pick" ''
          set -eu
          ${pkgs.procps}/bin/pkill -x rofi || true
          exec ${pkgs.rofi}/bin/rofi -modi emoji -show emoji
        '')
      ];

      services.cliphist = {
        enable = true;
        allowImages = false;
        extraOptions = [
          "-max-items"
          "500"
        ];
      };
    };
  };
}
