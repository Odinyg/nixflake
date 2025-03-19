{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    hyprlandstation = {
      enable = lib.mkEnableOption {
        description = "Enable  hyprland.";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.hyprlandstation.enable {

    services.swayidle.enable = true;
    home.packages = with pkgs; [
      grim
      eww
      swayidle
      wofi
      brightnessctl
      pyprland
      lxqt.lxqt-policykit
      swaynotificationcenter
      ulauncher
      wmctrl
      wl-clipboard
      slurp
      waybar
      hyprshade
      swww
      hyprpaper
      gtk-engine-murrine
      sassc
      gtk3
    ];
    xdg.configFile."wallpaper.png".source = ./wallpaper/wallpaper.png;
    xdg.configFile."hypr/hyprpaper.conf".source = ./config/hyprpaper.conf;
    xdg.configFile."hypr/pyprland.toml".source = ./config/pyprland.toml;
    xdg.configFile."hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
    xdg.configFile."waybar".source = ./config/waybar;
    xdg.configFile."swayidle".source = ./config/swayidle;
    xdg.configFile."hypr/shader/blue-light-filter.glsl".source = ./config/shader/blue-light-filter.glsl;
    programs.swaylock.enable = true;

  };

}
