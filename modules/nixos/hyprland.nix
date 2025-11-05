{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    hyprland = {
      enable = lib.mkEnableOption {
        description = "Enable Hyprland window manager";
        default = false;
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
