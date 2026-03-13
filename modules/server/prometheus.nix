{
  config,
  lib,
  ...
}:
let
  cfg = config.server.prometheus;
in
{
  options.server.prometheus = {
    enable = lib.mkEnableOption "Prometheus monitoring server";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Port for the Prometheus web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = cfg.port;
      retentionTime = "30d";
      globalConfig.scrape_interval = "15s";
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "10.10.30.110:9100" # psychosocial
                "10.10.50.110:9100" # byob
                "10.10.30.111:9100" # sugar
                "127.0.0.1:9100" # pulse (local)
              ];
            }
          ];
        }
        {
          job_name = "caddy";
          static_configs = [
            { targets = [ "10.10.30.110:2019" ]; }
          ];
        }
        {
          job_name = "authelia";
          static_configs = [
            { targets = [ "10.10.30.110:9959" ]; }
          ];
        }
      ];
    };

    systemd.services.prometheus = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
