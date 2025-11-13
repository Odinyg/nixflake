{ config, lib, ... }:
{

  options = {
    rofi = {
      enable = lib.mkEnableOption "Polybar, SXHKD, and Rofi for BSPWM";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.rofi.enable {
    programs.rofi.enable = true;
    services = {
      sxhkd.enable = true;
      picom.enable = true;
      polybar = {
        enable = true;
        script = "~/.config/polybar/launch.sh";
      };
    };
  };
}
