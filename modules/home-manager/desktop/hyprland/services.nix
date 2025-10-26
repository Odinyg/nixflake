{ config, lib, ... }: {

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    # Hyprlock screen locker
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 0;
          hide_cursor = true;
          no_fade_in = false;
        };

        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            size = "200, 50";
            position = "0, -80";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(202, 211, 245)";
            inner_color = "rgb(91, 96, 120)";
            outer_color = "rgb(24, 25, 38)";
            outline_thickness = 5;
            placeholder_text = ''<span foreground="##cad3f5">Password...</span>'';
            shadow_passes = 2;
          }
        ];
      };
    };

    # Hypridle idle management
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
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
            }
            {
              criteria = "DP-4";
              mode = "2560x1440";
              position = "1920,0"; # Middle monitor (main)
            }
            {
              criteria = "DP-5";
              mode = "2560x1440";
              position = "4480,0"; # Right monitor
            }
          ];
        }
        {
          profile.name = "p53-only";
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
      (hostname != "laptop" && hostname != "p53" && hostname != "station") [
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
