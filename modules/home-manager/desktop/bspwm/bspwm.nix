{
  config,
  lib,
  pkgs,
  ...
}:
{

  options = {
    bspwm = {
      enable = lib.mkEnableOption {
        description = "Enable bspwm.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.bspwm.enable {
    services = {
      picom.enable = true;
      xserver = {
        enable = true;
        windowManager.bspwm.enable = true;
        displayManager = {
          defaultSession = "none+bspwm";
          autoLogin.user = "$config.user";
          autoLogin.enable = false;
          sddm = {
            enable = true;
            wayland.enable = true;
          };
        };
        ## Perfect with zsa macros ##
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
