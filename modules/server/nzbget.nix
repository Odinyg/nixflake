{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.nzbget;
in
{
  options.server.nzbget = {
    enable = lib.mkEnableOption "NZBGet usenet download client";
    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/downloads";
      description = "Base download directory";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 6789;
      description = "Port for the NZBGet web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nzbget = {
      enable = true;
      group = "media";
      settings = {
        MainDir = cfg.downloadDir;
        DestDir = "${cfg.downloadDir}/complete";
        InterDir = "${cfg.downloadDir}/incomplete";
        NzbDir = "${cfg.downloadDir}/nzb";
        QueueDir = "${cfg.downloadDir}/queue";
        TempDir = "${cfg.downloadDir}/tmp";
        ScriptDir = "${cfg.downloadDir}/scripts";
        UnrarCmd = "${pkgs.unrar}/bin/unrar";
        SevenZipCmd = "${pkgs.p7zip}/bin/7za";
        CertStore = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
    };

    systemd.services.nzbget = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir}/nzb 0775 nzbget media -"
      "d ${cfg.downloadDir}/queue 0775 nzbget media -"
      "d ${cfg.downloadDir}/tmp 0775 nzbget media -"
      "d ${cfg.downloadDir}/scripts 0775 nzbget media -"
    ];
  };
}
