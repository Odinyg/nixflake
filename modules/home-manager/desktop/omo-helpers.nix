{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.omo-helpers;
  isStation = config.networking.hostName == "station";
in
{
  options.omo-helpers.enable = lib.mkEnableOption "Omarchy-style desktop UX helpers (station testbed)";
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.user} = lib.mkMerge [
      {
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
          (writeShellScriptBin "omo-power-menu" ''
            set -eu
            ${pkgs.procps}/bin/pkill -x rofi || true
            CHOICE=$(printf 'Lock\nLogout\nSuspend\nReboot\nShutdown' \
              | ${pkgs.rofi}/bin/rofi -dmenu -p "Power" -theme-str 'window { width: 20%; }')
            case "''${CHOICE:-}" in
              Lock) ${pkgs.systemd}/bin/loginctl lock-session ;;
              Logout) ${pkgs-unstable.hyprland}/bin/hyprctl dispatch exit ;;
              Suspend) ${pkgs.systemd}/bin/systemctl suspend ;;
              Reboot) ${pkgs.systemd}/bin/systemctl reboot ;;
              Shutdown) ${pkgs.systemd}/bin/systemctl poweroff ;;
              *) exit 0 ;;
            esac
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
      }
      (lib.mkIf isStation {
        wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
          "$mainMod, W, exec, omo-launch-or-focus zen-beta zen-beta"
          "$mainMod, E, exec, omo-launch-or-focus Thunar thunar"
          "$mainMod SHIFT, C, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a -n"
          "$mainMod SHIFT, V, exec, omo-clipboard-pick"
          "$mainMod, period, exec, omo-emoji-pick"
          "$mainMod SHIFT, O, exec, omo-window-pop"
          "$mainMod SHIFT, E, exec, omo-power-menu"
        ];

        home.packages = [
          (pkgs.writeShellScriptBin "omo-toggle-animations" ''
            set -eu
            STATE="''${XDG_STATE_HOME:-$HOME/.local/state}/hypr/animations.conf"
            TPL="$HOME/.config/hypr/omo-animations-on.conf"
            if [ -s "$STATE" ]; then
              : > "$STATE"
              ${pkgs.libnotify}/bin/notify-send "Animations" "Off" -t 1500
            else
              cat "$TPL" > "$STATE"
              ${pkgs.libnotify}/bin/notify-send "Animations" "On" -t 1500
            fi
            ${pkgs-unstable.hyprland}/bin/hyprctl reload >/dev/null
          '')
        ];

        xdg.configFile."hypr/omo-animations-on.conf".text = ''
          animations {
            enabled = true
            bezier = omoBezier, 0.05, 0.9, 0.1, 1.05
            animation = windows, 1, 4, omoBezier
            animation = windowsOut, 1, 4, default, popin 80%
            animation = border, 1, 10, default
            animation = fade, 1, 7, default
            animation = workspaces, 1, 2, default
          }
        '';

        wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
          # omo-helpers: runtime-toggleable animations via sourced state file
          source = ~/.local/state/hypr/animations.conf
        '';

        home.activation.ensureOmoAnimationState = {
          after = [ "linkGeneration" ];
          before = [ ];
          data = ''
            mkdir -p "$HOME/.local/state/hypr"
            if [ ! -f "$HOME/.local/state/hypr/animations.conf" ]; then
              touch "$HOME/.local/state/hypr/animations.conf"
            fi
          '';
        };

        home.activation.omoWaybarPatchConfig = {
          after = [ "linkGeneration" ];
          before = [ ];
          data = ''
            WAYBAR_CFG="$HOME/.config/waybar/config"
            if [ -f "$WAYBAR_CFG" ] && ! ${pkgs.jq}/bin/jq -e '."modules-right" | index("custom/power")' "$WAYBAR_CFG" >/dev/null 2>&1; then
              TMP=$(mktemp)
              ${pkgs.jq}/bin/jq '
                ."modules-right" += ["custom/power"] |
                ."custom/power" = {
                  "format": "\uf011",
                  "tooltip": true,
                  "tooltip-format": "Power Menu",
                  "on-click": "omo-power-menu"
                }
              ' "$WAYBAR_CFG" > "$TMP" && mv "$TMP" "$WAYBAR_CFG"
              chmod u+w "$WAYBAR_CFG"
            fi
          '';
        };

        home.activation.omoWaybarPatchStyle = {
          after = [ "omoWaybarPatchConfig" ];
          before = [ ];
          data = ''
                        WAYBAR_CSS="$HOME/.config/waybar/style.css"
                        if [ -f "$WAYBAR_CSS" ] && ! grep -q "#custom-power" "$WAYBAR_CSS"; then
                          cat >> "$WAYBAR_CSS" <<'CSSEOF'

            #custom-power {
              color: @red;
              padding: 0 10px;
            }
            CSSEOF
                        fi
          '';
        };

        home.activation.omoWaybarReload = {
          after = [ "omoWaybarPatchStyle" ];
          before = [ ];
          data = ''
            ${pkgs.procps}/bin/pkill -SIGUSR2 -x waybar 2>/dev/null || true
          '';
        };
      })
    ];
  };
}
