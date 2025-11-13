{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    wireless = {
      enable = lib.mkEnableOption "wireless";
    };
  };
  config = lib.mkIf config.wireless.enable {
    #  networking.hostName = "XPS";
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    environment.systemPackages = with pkgs; [
      networkmanagerapplet

      networkmanager-openvpn
    ];
  };
}
