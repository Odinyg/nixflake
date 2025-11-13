{
  config,
  lib,
  pkgs,
  ...
}:
{

  options = {
    bspwm = {
      enable = lib.mkEnableOption "BSPWM window manager";
    };
  };

  config = lib.mkIf config.bspwm.enable {
    services = {
      displayManager = {
        autoLogin.user = "$config.user";
        autoLogin.enable = false;
        defaultSession = "none+bspwm";
        sddm = {
          wayland.enable = true;
          enable = true;
        };
      };
      picom.enable = true;
      xserver = {
        enable = true;
        windowManager.bspwm.enable = true;
        xkb.layout = "us";
        xkb.variant = "altgr-intl";
        xkb.options = "compose:ralt";
      };
    };

    environment.systemPackages = with pkgs; [
      polkit_gnome
      tint2
      xclip
      xorg.xinit
      betterlockscreen
      xorg.xbacklight
    ];
  };
}
