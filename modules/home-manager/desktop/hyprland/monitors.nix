{ config, lib, ... }: {

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland.extraConfig =
      let hostname = config.networking.hostName;
      in if hostname == "station" then ''
        # Station: Workspace assignments (monitors managed by kanshi)
        workspace = 1, monitor:HDMI-A-1, default:true, gapsout:0 200 400 200
        workspace = 2, monitor:HDMI-A-1, gapsout:0 200 400 200
        workspace = 3, monitor:HDMI-A-1, gapsout:0 200 400 200
        workspace = 4, monitor:HDMI-A-1, gapsout:0 200 400 200
        workspace = 5, monitor:HDMI-A-1, gapsout:0 200 400 200

        workspace = 6, monitor:DP-1, default:true
        workspace = 7, monitor:DP-1
        workspace = 8, monitor:DP-1
        workspace = 9, monitor:DP-1
        workspace = 0, monitor:DP-1
      '' else if hostname == "VNPC-21" then ''
        # VNPC-21: Triple monitor setup
        workspace = 1, monitor:DP-4, default:true
        workspace = 2, monitor:DP-4
        workspace = 3, monitor:DP-4
        workspace = 4, monitor:DP-4
        workspace = 5, monitor:DP-4

        workspace = 6, monitor:DP-5, default:true
        workspace = 7, monitor:DP-5
        workspace = 8, monitor:DP-5

        workspace = 9, monitor:HDMI-A-1
        workspace = 0, monitor:HDMI-A-1
      '' else ''
        # Default configuration for other hosts
        workspace = 1, default:true
      '';
  };
}
