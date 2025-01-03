{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./station.nix ];
  options = {
    hyprland = {
      enable = lib.mkEnableOption {
        description = "Enable  hyprland.";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {

    services.swayidle.enable = true;
    home.packages = with pkgs; [
      grim
      eww
      swayidle
      wofi
      brightnessctl
      #mako
      lxqt.lxqt-policykit
      copyq
      swaynotificationcenter
      ulauncher
      wmctrl
      wl-clipboard
      slurp
      waybar
      hyprshade
      hyprpaper
      gtk-engine-murrine
      sassc
      gtk3
      gnome.gnome-themes-extra
    ];
    xdg.configFile."wallpaper.png".source = ./wallpaper/wallpaper.png;
    xdg.configFile."hypr/hyprpaper.conf".source = ./config/hyprpaper.conf;
    xdg.configFile."hypr/pyprland.toml".source = ./config/pyprland.toml;
    #   xdg.configFile."hypr/hyprland.conf".source = ./config/hyprland.conf;
    xdg.configFile."hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
    xdg.configFile."waybar".source = ./config/waybar;
    xdg.configFile."swayidle".source = ./config/swayidle;
    xdg.configFile."hypr/shader/blue-light-filter.glsl".source = ./config/shader/blue-light-filter.glsl;
    programs.swaylock.enable = true;

  };

}
