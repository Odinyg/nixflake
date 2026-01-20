{ config, lib, pkgs-unstable, ... }: {

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    programs.hyprpanel = {
      enable = true;
      package = pkgs-unstable.hyprpanel;
      settings = {
        layout = {
          bar.layouts = {
            "*" = {
              left = [ "dashboard" "media" ];
              middle = [ "workspaces" ];
              right = [
                "volume"
                "network"
                "bluetooth"
                "clock"
                "systray"
                "notifications"
              ];
            };
          };
        };

        bar.launcher.autoDetectIcon = true;
        bar.workspaces.show_icons = true;

        menus.clock = {
          time = {
            military = true;
            hideSeconds = true;
          };
          weather.unit = "metric";
        };

        bar.clock = {
          format = "%H:%M - %d/%m W%V";
          showWeek = true;
        };

        menus.dashboard.directories.enabled = false;
        menus.dashboard.stats.enable_gpu = true;

        theme.bar.transparent = true;

        theme.font = {
          name = "CaskaydiaCove NF";
          size = "16px";
        };
      };
    };
  };
}
