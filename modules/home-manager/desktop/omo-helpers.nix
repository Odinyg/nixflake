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
