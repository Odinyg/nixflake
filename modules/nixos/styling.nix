{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    styling = {
      enable = lib.mkEnableOption {
        description = "Enable styling and theming.";
        default = false;
      };

      theme = lib.mkOption {
        type = lib.types.str;
        default = "nord";
        description = "Base16 theme to use";
      };

      wallpaper = lib.mkOption {
        type = lib.types.path;
        default = ../../modules/home-manager/desktop/hyprland/wallpaper/wallpaper.png;
        description = "Path to wallpaper image";
      };

      polarity = lib.mkOption {
        type = lib.types.enum [
          "light"
          "dark"
        ];
        default = "dark";
        description = "Theme polarity";
      };

      opacity = {
        terminal = lib.mkOption {
          type = lib.types.float;
          default = 0.85;
          description = "Terminal opacity";
        };
      };

      cursor = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.bibata-cursors;
          description = "Cursor theme package";
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "Bibata-Modern-Ice";
          description = "Cursor theme name";
        };

        size = lib.mkOption {
          type = lib.types.int;
          default = 18;
          description = "Cursor size";
        };
      };

      autoEnable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic stylix configuration";
      };
    };
  };

  config = lib.mkIf config.styling.enable {
    stylix.enable = true;

    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.styling.theme}.yaml";

    stylix.image = config.styling.wallpaper;

    stylix.polarity = config.styling.polarity;

    stylix.opacity.terminal = config.styling.opacity.terminal;

    stylix.cursor = {
      package = config.styling.cursor.package;
      name = config.styling.cursor.name;
      size = config.styling.cursor.size;
    };

    stylix.autoEnable = config.styling.autoEnable;

    home-manager.users.${config.user} = {
      gtk = {
        iconTheme = {
          package = pkgs.zafiro-icons;
          name = "breeze";
        };
      };
    };
  };
}
