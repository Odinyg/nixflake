{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.freshrss;
in
{
  options.server.freshrss = {
    enable = lib.mkEnableOption "FreshRSS RSS aggregator";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8282;
      description = "Port for the FreshRSS web interface (nginx listener)";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "freshrss.pytt.io";
      description = "Public domain for FreshRSS";
    };
    defaultUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Default admin username";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.freshrss_admin_password = {
      owner = "freshrss";
    };

    services.freshrss = {
      enable = true;
      baseUrl = "https://${cfg.domain}";
      defaultUser = cfg.defaultUser;
      passwordFile = config.sops.secrets.freshrss_admin_password.path;
      authType = "none";
      language = "en";

      api.enable = true;

      database.type = "sqlite";

      virtualHost = cfg.domain;
    };

    # Override nginx to listen on cfg.port instead of 80 (Nextcloud already uses 80)
    services.nginx.virtualHosts.${cfg.domain} = {
      listen = [
        {
          addr = "0.0.0.0";
          port = cfg.port;
        }
      ];
    };

    systemd.services.phpfpm-freshrss = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
