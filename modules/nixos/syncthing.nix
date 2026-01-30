{ config, lib, pkgs-unstable, ... }:
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
        package = pkgs-unstable.syncthing; # Use unstable to match config version
        user = "${config.user}";
        dataDir = "/home/${config.user}/Documents";
        configDir = "/home/${config.user}/.config/syncthing";
        overrideDevices = true; # overrides any devices added or deleted through the WebUI
        settings = {
          devices = { };
        };
      };
    };
  };
}
