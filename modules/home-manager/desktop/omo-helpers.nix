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
  # rofi-emoji plugin path — set ROFI_PLUGIN_PATH in the script so the
  # already-installed pkgs.rofi finds it without a conflicting second rofi derivation
  rofiEmojiPluginDir = "${pkgs.rofi-emoji}/lib/rofi";
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
          # Omarchy TUI + GUI utilities
          wiremix
          bluetui
          impala
          localsend
          btop
          wf-recorder
          grim
          slurp
          satty
          (writeShellScriptBin "omo-tui" ''
            set -eu
            # Launch a TUI in ghostty with class=waybar-popup so hyprland
            # window rules float + center + size it to 800x500.
            exec ghostty --class=waybar-popup -e "$@"
          '')
          (writeShellScriptBin "omo-capture-menu" ''
            set -eu
            ${pkgs.procps}/bin/pkill -x rofi || true
            SHOT_DIR="$HOME/Pictures/screenshots"
            mkdir -p "$SHOT_DIR"
            CHOICE=$(printf 'Region (annotate)\nRegion (copy+save)\nFullscreen\nColor picker\nRecord region (toggle)' \
              | ${pkgs.rofi}/bin/rofi -dmenu -p "Capture" -theme-str 'window { width: 25%; }')
            TS=$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)
            case "''${CHOICE:-}" in
              "Region (annotate)")
                ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" -t ppm - \
                  | ${pkgs.satty}/bin/satty --filename - --fullscreen \
                      --output-filename "$SHOT_DIR/satty-$TS.png"
                ;;
              "Region (copy+save)")
                ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" - \
                  | ${pkgs.coreutils}/bin/tee "$SHOT_DIR/screenshot-$TS.png" \
                  | ${pkgs.wl-clipboard}/bin/wl-copy
                ${pkgs.libnotify}/bin/notify-send "Screenshot" "Copied + saved" -t 2000
                ;;
              "Fullscreen")
                ${pkgs.grim}/bin/grim "$SHOT_DIR/fullscreen-$TS.png"
                ${pkgs.libnotify}/bin/notify-send "Screenshot" "Saved fullscreen" -t 2000
                ;;
              "Color picker")
                ${pkgs.hyprpicker}/bin/hyprpicker -a -n
                ;;
              "Record region (toggle)")
                if ${pkgs.procps}/bin/pgrep -x wf-recorder >/dev/null; then
                  ${pkgs.procps}/bin/pkill -INT -x wf-recorder
                  ${pkgs.libnotify}/bin/notify-send "Recording" "Stopped" -t 2000
                else
                  ${pkgs.wf-recorder}/bin/wf-recorder \
                    -g "$(${pkgs.slurp}/bin/slurp)" \
                    -f "$SHOT_DIR/recording-$TS.mp4" &
                  ${pkgs.libnotify}/bin/notify-send "Recording" "Started" -t 2000
                fi
                ;;
              *) exit 0 ;;
            esac
          '')
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
            # Chromium --app= sets WM_CLASS to chrome-<host>; use that for focus matching
            HOST=$(printf '%s' "$URL" | ${pkgs.gnused}/bin/sed -E 's#^https?://([^/]+).*#\1#')
            CLASS="chrome-$HOST"
            mkdir -p "$APPDIR"
            cat > "$FILE" <<EOF
            [Desktop Entry]
            Type=Application
            Name=$NAME
            Exec=launch-or-focus $CLASS "chromium --app=$URL"
            Icon=chromium
            Categories=Network;WebBrowser;
            StartupWMClass=$CLASS
            NoDisplay=false
            EOF
            ${pkgs.desktop-file-utils}/bin/desktop-file-validate "$FILE" \
              || { ${pkgs.libnotify}/bin/notify-send "omo-webapp-install" "Invalid desktop file" -t 3000; exit 1; }
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
            W=$(printf '%s' "$RES" | ${pkgs.coreutils}/bin/cut -dx -f1)
            H=$(printf '%s' "$RES" | ${pkgs.coreutils}/bin/cut -dx -f2)
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
            export ROFI_PLUGIN_PATH="${rofiEmojiPluginDir}"
            export XDG_DATA_DIRS="${pkgs.rofi-emoji}/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
            exec ${pkgs.rofi}/bin/rofi -modi emoji -show emoji
          '')
          (writeShellScriptBin "omo-hotkey-finder" ''
            set -eu
            # Dump active hyprland binds, decode modmask into readable names,
            # then show in rofi. Inspired by Omarchy's omarchy-menu-keybindings.
            ${pkgs.procps}/bin/pkill -x rofi || true
            ${pkgs-unstable.hyprland}/bin/hyprctl -j binds \
              | ${pkgs.jq}/bin/jq -r '
                  def mods($m):
                    [ (if ($m % 2) == 1 then "SHIFT" else empty end),
                      (if (($m / 4 | floor) % 2) == 1 then "CTRL" else empty end),
                      (if (($m / 8 | floor) % 2) == 1 then "ALT" else empty end),
                      (if (($m / 64 | floor) % 2) == 1 then "SUPER" else empty end)
                    ] | join(" + ");
                  .[]
                  | (.modmask // 0) as $m
                  | (mods($m)) as $mod
                  | ( .key // ("code:" + (.keycode | tostring)) ) as $key
                  | (.description // "") as $desc
                  | ((.dispatcher // "") + " " + (.arg // "")) as $action
                  | (if $mod == "" then $key else $mod + " + " + $key end) as $combo
                  | $combo + "\t→ " + (if $desc != "" then $desc else ($action | sub("^exec\\s+"; "")) end)
                ' \
              | ${pkgs.coreutils}/bin/sort -u \
              | ${pkgs.gnused}/bin/sed 's/\t/  /' \
              | ${pkgs.rofi}/bin/rofi -dmenu -p "Hotkeys" \
                  -i \
                  -theme-str 'window { width: 60%; } listview { lines: 20; }'
          '')
          (writeShellScriptBin "omo-close-all" ''
            set -eu
            ${pkgs-unstable.hyprland}/bin/hyprctl clients -j \
              | ${pkgs.jq}/bin/jq -r '.[].address' \
              | while read -r addr; do
                  [ -n "$addr" ] && ${pkgs-unstable.hyprland}/bin/hyprctl dispatch closewindow "address:$addr"
                done
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
        # Drop the base bindings so omo-launch-or-focus doesn't double-fire
        # with the raw `zen-beta` / `thunar` binds from keybindings.nix.
        wayland.windowManager.hyprland.settings.unbind = [
          "$mainMod, W"
          "$mainMod, E"
        ];
        wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
          "$mainMod, W, exec, omo-launch-or-focus zen-beta zen-beta"
          "$mainMod, E, exec, omo-launch-or-focus Thunar thunar"
          "$mainMod SHIFT, C, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a -n"
          "$mainMod SHIFT, V, exec, omo-clipboard-pick"
          "$mainMod, period, exec, omo-emoji-pick"
          "$mainMod SHIFT, O, exec, omo-window-pop"
          "$mainMod SHIFT, E, exec, omo-power-menu"
          "CTRL ALT, Delete, exec, omo-close-all"

          # Omarchy TUI / utility shortcuts
          "$mainMod CTRL, A, exec, omo-tui wiremix"
          "$mainMod CTRL, B, exec, omo-tui bluetui"
          "$mainMod CTRL, W, exec, omo-tui impala"
          "$mainMod CTRL, S, exec, localsend_app"
          "$mainMod CTRL, T, exec, omo-tui btop"
          "$mainMod CTRL, C, exec, omo-capture-menu"
          "$mainMod SHIFT, return, exec, ghostty -e tmux new-session -A -s main"
          ''$mainMod SHIFT, M, exec, launch-or-focus chrome-music.youtube.com "chromium --app=https://music.youtube.com"''
          "$mainMod, slash, exec, omo-hotkey-finder"
          "$mainMod, tab, workspace, previous"
        ];

        home.packages = [
          (pkgs.writeShellScriptBin "omo-toggle-animations" ''
            set -eu
            STATE="''${XDG_STATE_HOME:-$HOME/.local/state}/hypr/animations.conf"
            TPL="$HOME/.config/hypr/omo-animations-on.conf"
            if [ -s "$STATE" ]; then
              : > "$STATE"
            else
              cat "$TPL" > "$STATE"
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

        home.activation.omoWaybarPatchOmarchy = {
          after = [ "omoWaybarPatchConfig" ];
          before = [ ];
          data = ''
            WAYBAR_CFG="$HOME/.config/waybar/config"
            if [ -f "$WAYBAR_CFG" ] && ! ${pkgs.jq}/bin/jq -e '."custom/capture"' "$WAYBAR_CFG" >/dev/null 2>&1; then
              TMP=$(mktemp)
              ${pkgs.jq}/bin/jq '
                .pulseaudio["on-click"] = "omo-tui wiremix" |
                .bluetooth["on-click"] = "omo-tui bluetui" |
                .network["on-click"] = "omo-tui impala" |
                ."custom/share" = {
                  "format": "\uf1e0",
                  "tooltip": true,
                  "tooltip-format": "Share (LocalSend)",
                  "on-click": "localsend_app"
                } |
                ."custom/activity" = {
                  "format": "\uf2db",
                  "tooltip": true,
                  "tooltip-format": "Activity (btop)",
                  "on-click": "omo-tui btop"
                } |
                ."custom/capture" = {
                  "format": "\uf030",
                  "tooltip": true,
                  "tooltip-format": "Capture",
                  "on-click": "omo-capture-menu"
                } |
                ."modules-right" |=
                  ((. // []) - ["custom/share","custom/activity","custom/capture"])
                  + ["custom/capture","custom/share","custom/activity"]
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
            #custom-share, #custom-activity, #custom-capture {
              padding: 0 8px;
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
