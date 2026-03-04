{ config, lib, ... }:
{

  options = {
    syncthing = {
      enable = lib.mkEnableOption "syncthing";
    };
  };
  config = lib.mkIf config.syncthing.enable {
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
