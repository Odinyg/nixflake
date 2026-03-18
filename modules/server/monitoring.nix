{
  config,
  lib,
  ...
}:
let
  lokiUrl = "http://10.10.30.112:3100/loki/api/v1/push";
  hostname = config.networking.hostName;
in
{
  # Grafana Alloy for log + metric collection on every server
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
        url = "${lokiUrl}"
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
}
