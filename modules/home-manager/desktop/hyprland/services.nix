{ config, lib, ... }: {

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    # Swaylock screen locker
    programs.swaylock.enable = true;

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
              criteria = "DP-2";
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
