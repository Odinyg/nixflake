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
   home.packages = [
      pkgs.waybar
    ];
    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
    wayland.windowManager.hyprland.enable = true;

  };
}
