{
  lib,
  config,
  pkgs,
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
      ];
    };
  };
}
