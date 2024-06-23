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
      eww
      wofi-emoji
      wofi
      tofi
      slurp
      waybar
      hyprshade
      hyprpaper
      gtk-engine-murrine
      sassc
      gtk3
      walker
      gnome.gnome-themes-extra
    ];
    xdg.configFile."wallpaper.png".source = ./wallpaper.png;
    xdg.configFile."hypr/hyprpaper.conf".source = ./config/hyprpaper.conf;
    xdg.configFile."hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
    xdg.configFile."waybar".source = ./config/waybar;
    xdg.configFile."hypr/shader/blue-light-filter.glsl".source = ./config/shader/blue-light-filter.glsl;
    xdg.configFile."hypr/hyprland.conf".source = ./config/hyprland.conf;
    programs.swaylock.enable = true;





};
}
