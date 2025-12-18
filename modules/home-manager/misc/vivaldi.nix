{ config, lib, pkgs, ... }:
{

  options = {
    vivaldi = {
      enable = lib.mkEnableOption "Vivaldi browser";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.vivaldi.enable {
    home.packages = with pkgs; [
      vivaldi
      vivaldi-ffmpeg-codecs
    ];

    # Wayland environment variables for Vivaldi
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
