{
  config,
  lib,
  pkgs,
  stylix,
  ...
}:
{
  options = {
    styling = {
      enable = lib.mkEnableOption {
        description = "Enable styling.";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.styling.enable {
    config = lib.mkIf config.styling.enable {
      gtk.iconTheme.package = pkgs.zafiro-icons;
      gtk.iconTheme.name = "breeze";

      #### Had to disable bco stylix.image' is used but not defined bug and home-manager

      #     stylix.enable = true;
      #     stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
      #     stylix.image = ../../modules/home-manager/desktop/hyprland/wallpaper.png;
      #     stylix.polarity = "dark";
      #     stylix.opacity.terminal = 0.85;
      #     stylix.cursor.package = pkgs.bibata-cursors;
      #     stylix.cursor.name = "Bibata-Modern-Ice";
      #     stylix.cursor.size = 16;

    };
  };
}
