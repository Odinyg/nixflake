{ config, lib, ... }:
{

  options = {
    syncthing = {
      enable = lib.mkEnableOption "syncthing";
    };
  };
  config = lib.mkIf config.syncthing.enable {
    networking.extraHosts = "127.0.0.1 syncthing.local";
    services = {
      syncthing = {
        enable = true;
        user = "${config.user}";
        dataDir = "/home/${config.user}/Documents";
        configDir = "/home/${config.user}/.config/syncthing";
        overrideDevices = false;
      };
    };
  };
}
