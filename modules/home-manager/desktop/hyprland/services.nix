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

    # Wallpaper rotation — picks a random wallpaper every 2 hours
    systemd.user.services.wallpaper-rotate = {
      Unit.Description = "Rotate desktop wallpaper";
      Service = {
        Type = "oneshot";
        ExecStart = "%h/.config/hypr/random-wallpaper.sh";
      };
    };

    systemd.user.timers.wallpaper-rotate = {
      Unit.Description = "Rotate wallpaper every 2 hours";
      Timer = {
        OnActiveSec = "0";
        OnUnitActiveSec = "2h";
        RandomizedDelaySec = "30min";
      };
      Install.WantedBy = [ "timers.target" ];
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
            timeout = 600;
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

    # Kanshi dynamic display configuration
    services.kanshi = {
      enable = true;
      settings =
        if (config.hyprland.kanshi.profiles != [ ]) then
          config.hyprland.kanshi.profiles
        else
          # Default fallback profile for hosts without custom configuration
          [
            {
              profile.name = "default";
              profile.outputs = [
                {
                  criteria = "eDP-1";
                  mode = "1920x1080";
                  scale = 1.0;
                }
              ];
            }
          ];
    };
  };
}
