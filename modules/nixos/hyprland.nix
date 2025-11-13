{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    hyprland = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hyprland window manager";
      };

      kanshi = {
        profiles = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [];
          description = "Kanshi display profiles for dynamic display configuration";
          example = lib.literalExpression ''
            [
              {
                profile.name = "docked";
                profile.outputs = [
                  { criteria = "eDP-1"; position = "0,0"; scale = 1.25; }
                  { criteria = "HDMI-A-1"; mode = "2560x1440"; position = "1920,0"; }
                ];
              }
            ]
          '';
        };
      };

      monitors = {
        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Additional Hyprland monitor and workspace configuration";
          example = lib.literalExpression ''
            monitor = HDMI-A-1, 1920x1080@60, 0x0, 1
            workspace = 1, monitor:HDMI-A-1, default:true
          '';
        };
      };
    };
  };

  config = lib.mkIf config.hyprland.enable {

    programs.hyprland.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = "*";
        hyprland = {
          default = [ "hyprland" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        };
      };
    };

    security.pam.services.swaylock = {};
  };
}
