{ config, lib, pkgs, pkgs-unstable, ... }: {

  config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable {
    home.packages = (with pkgs-unstable; [
      # Core Hyprland ecosystem (from unstable for latest features)
      waybar # Status bar
      hyprpanel # Alternative panel
      hyprpaper # Wallpaper daemon
      pyprland # Scratchpad & window manager plugins
      hyprshade # Shader control
      swww # Animated wallpaper daemon
    ]) ++ (with pkgs; [
      # Screenshot & Image Tools
      grim # Screenshot tool
      slurp # Region selector
      vimiv-qt # Image viewer

      # Window Management
      wmctrl # Window control utility

      # Appearance & Theming
      gtk-engine-murrine # GTK engine
      sassc # Sass compiler for themes
      gtk3 # GTK3 libraries

      # Notifications & UI
      swaynotificationcenter # Notification daemon
      eww # ElKowar's Wacky Widgets
      rofi # Application launcher
      brightnessctl # Brightness control

      # Authentication & Security
      lxqt.lxqt-policykit # PolicyKit authentication agent

      # Clipboard & Selection
      xclip # X11 clipboard tool
      wl-clipboard # Wayland clipboard utilities
      wl-clip-persist
    ]);

    # XDG config files
    xdg.configFile = {
      "wallpaper.png".source = ./wallpaper/wallpaper.png;
      "hypr/hyprpaper.conf".source = ./config/hyprpaper.conf;
      "hypr/random-wallpaper.sh" = {
        source = ./scripts/random-wallpaper.sh;
        executable = true;
      };
      "hypr/pyprland.toml".source = ./config/pyprland.toml;
      "hypr/hyprshade.toml".source = ./config/shader/hyprshade.toml;
      "hypr/shader/blue-light-filter.glsl".source =
        ./config/shader/blue-light-filter.glsl;
      "waybar".source = ./config/waybar;
      "rofi/config.rasi".source = ./config/rofi.rasi;
      "rofi/nord.rasi".source = ./config/rofi-nord.rasi;
      "rofi/rounded-common.rasi".source = ./config/rounded-common.rasi;
    };
  };
}
