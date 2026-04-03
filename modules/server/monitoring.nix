{
  config,
  lib,
  ...
}:
let
  cfg = config.server.monitoring;
  hostname = config.networking.hostName;
in
{
  options.server.monitoring = {
    enable = lib.mkEnableOption "Grafana Alloy + Prometheus node exporter";
    lokiUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://10.10.30.112:3100/loki/api/v1/push";
      description = "Loki push endpoint for log collection";
    };
  };

  config = lib.mkIf cfg.enable {
    # Grafana Alloy for log + metric collection
    services.alloy.enable = true;

    # Grant journal read access for log collection
    systemd.services.alloy.serviceConfig = {
      SupplementaryGroups = [ "systemd-journal" ];
    };

    environment.etc."alloy/config.alloy".text = ''
      loki.source.journal "journal" {
        forward_to = [loki.write.default.receiver]
        labels = {
          host = "${hostname}",
          job  = "journal",
        }
      }

      loki.write "default" {
        endpoint {
          url = "${cfg.lokiUrl}"
        }
      }
    '';

    # Prometheus node exporter for system metrics
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = 9100;
    };
    networking.firewall.allowedTCPPorts = [ 9100 ];
  };
}
