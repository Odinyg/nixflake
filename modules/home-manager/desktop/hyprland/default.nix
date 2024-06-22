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
      rofi-wayland
    ];
    xdg.configFile."wallpaper.png".source = ./wallpaper.png;
    xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
    xdg.configFile."hypr/hyprshade.toml".source = ./shader/hyprshade.toml;
    xdg.configFile."hypr/shader/blue-light-filter.glsl".source = ./shader/blue-light-filter.glsl;
    programs.swaylock.enable = true;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.nightfox-gtk-theme;
        name = "Nightfox-Dusk-B";
      };
      iconTheme = {
        package = pkgs.zafiro-icons;
        name = "Zafiro-icons-Dark";
      };
      cursorTheme = {
        package = pkgs.graphite-cursors;
        name = "graphite-dark";
        size = 17;

      };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    };
    home.sessionVariables.GTK_THEME = "Nightfox-Dusk-B";
    qt.enable = true;
    qt.platformTheme.name = "gtk";
    qt.style.name = "adwaita-dark";




};
}
