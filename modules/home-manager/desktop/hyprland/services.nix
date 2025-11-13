{ config, lib, ... }: {

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    # Swaylock screen locker
    programs.swaylock = {
      enable = true;
      settings = {
        # Let Stylix handle color theming
        font-size = 24;
        indicator-idle-visible = false;
        indicator-radius = 100;
        indicator-thickness = 7;
        show-failed-attempts = true;
        image = lib.mkForce "~/.config/hypr/wallpaper/wallpaper.png";
        scaling = "fill";
      };
    };

    # Hypridle idle management
    services.hypridle = {
      enable = true;
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

    # Kanshi dynamic display configuration
    services.kanshi = {
      enable = true;
      settings = if (config.hyprland.kanshi.profiles != []) then
        config.hyprland.kanshi.profiles
      else
        # Default fallback profile for hosts without custom configuration
        [
          {
            profile.name = "default";
            profile.outputs = [{
              criteria = "eDP-1";
              mode = "1920x1080";
              scale = 1.0;
            }];
          }
        ];
    };
  };
}
