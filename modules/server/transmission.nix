{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.transmission;
in
{
  options.server.transmission = {
    enable = lib.mkEnableOption "Transmission BitTorrent client";
    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/downloads";
      description = "Base download directory";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9091;
      description = "Port for the Transmission RPC interface";
    };
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      group = "media";
      openRPCPort = true;
      settings = {
        download-dir = "${cfg.downloadDir}/complete";
        incomplete-dir = "${cfg.downloadDir}/incomplete";
        incomplete-dir-enabled = true;
        rpc-port = cfg.port;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
      };
    };

    systemd.services.transmission = {
      after = [ "mnt-downloads.mount" ];
      requires = [ "mnt-downloads.mount" ];
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir}/complete 0775 transmission media -"
      "d ${cfg.downloadDir}/incomplete 0775 transmission media -"
    ];
  };
}
