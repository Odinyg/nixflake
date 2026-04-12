{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.wireless;
in
{
  options = {
    wireless = {
      enable = lib.mkEnableOption "wireless";
    };
  };
  config = lib.mkIf cfg.enable {
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };
    environment.systemPackages = with pkgs; [
      networkmanagerapplet

      networkmanager-openvpn
    ];
  };
}
