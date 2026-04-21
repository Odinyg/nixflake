{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.hyprland;
in
{
  options = {
    hyprland = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hyprland window manager";
      };

      idleLockTimeout = lib.mkOption {
        type = lib.types.int;
        default = 600;
        description = "Seconds of user inactivity before the session is locked via hypridle/swaylock";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    programs.hyprland = {
      enable = true;
      package = pkgs-unstable.hyprland;
      portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = "*";
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        };
      };
    };

    security.pam.services.swaylock = { };
  };
}
