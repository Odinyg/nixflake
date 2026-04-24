{
  config,
  lib,
  pkgs-unstable,
  ...
}:
{

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    # Swaylock screen locker
    programs.swaylock = {
      enable = true;
      settings = {
        font-size = 24;
        indicator-idle-visible = false;
        indicator-radius = 100;
        indicator-thickness = 7;
        show-failed-attempts = true;
        image = lib.mkDefault "~/.config/current-wallpaper.png";
        scaling = "fill";
      };
    };

    # Hypridle idle management
    services.hypridle = {
      enable = true;
      package = pkgs-unstable.hypridle;
      settings = {
        general = {
          lock_cmd = "pidof swaylock || swaylock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = config.hyprland.idleLockTimeout;
            on-timeout = "loginctl lock-session";
          }
        ];
      };
    };

    # SwayOSD on-screen display for volume/brightness/capslock
    services.swayosd = {
      enable = true;
      topMargin = 0.85;
    };

    # Hyprsunset — blue-light filter with day/night schedule
    services.hyprsunset = {
      enable = true;
      settings = {
        max-gamma = 100;
        profile = [
          {
            time = "6:00";
            identity = true;
          }
          {
            time = "20:00";
            temperature = 4000;
          }
        ];
      };
    };
  };
}
