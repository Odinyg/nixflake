{ config, lib, pkgs, ... }: {
  options = {
    hyprland = {
      enable = lib.mkEnableOption {
        description = "Enable  hyprland.";
        default = false;
      }; 
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    home.packages = with pkgs; [
      grim
      slurp
      waybar
      hyprshade
    ];
    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
    xdg.configFile."hypr/hyprshade.toml".source = ./hyprshade.toml;
    programs.swaylock.enable = true;
#    wayland.windowManager.hyprland = {
#      enable = true;
#      xwayland.enable = true;
#      systemd.enable = true;
#
#    };

  };
}
