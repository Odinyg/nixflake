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
      settings = let hostname = config.networking.hostName;
      in lib.optionals (hostname == "VNPC-21") [
        # External Monitors Profile for VNPC-21
        {
          profile.name = "external-monitors";
          profile.outputs = [
            {
              criteria = "eDP-1";
              position = "0,0"; # Laptop screen
              scale = 1.25;
            }
            {
              criteria = "DP-4";
              mode = "2560x1440";
              position = "1536,0"; # Middle monitor (adjusted for eDP-1 scale)
            }
            {
              criteria = "DP-5";
              mode = "2560x1440";
              position = "4096,0"; # Right monitor (1536 + 2560)
            }
          ];
        }
        {
          profile.name = "vnpc-21-only";
          profile.outputs = [{
            criteria = "eDP-1";
            status = "enable";
            mode = "1920x1080";
            scale = 1.0;
          }];
        }
      ] ++ lib.optionals (hostname == "laptop") [
        # Profile for laptop
        {
          profile.name = "laptop-only";
          profile.outputs = [{
            criteria = "eDP-1";
            status = "enable";
            mode = "1920x1200";
            scale = 1.0;
          }];
        }
      ] ++ lib.optionals (hostname == "station") [
        # Profile for station
        {
          profile.name = "station-only";
          profile.outputs = [
            {
              criteria = "DP-1";
              mode = "1920x1080@164.96";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "HDMI-A-1";
              mode = "3840x2160@119.88";
              position = "1920,0";
              scale = 1.0;
            }
          ];
        }
      ] ++ lib.optionals
      (hostname != "laptop" && hostname != "VNPC-21" && hostname != "station") [
        # Default Profile
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
