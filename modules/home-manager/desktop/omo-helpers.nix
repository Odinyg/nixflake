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
