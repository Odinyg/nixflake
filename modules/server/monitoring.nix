{ ... }:

{
  # Grafana Alloy for log + metric collection on every server
  services.alloy.enable = true;

  # Grant journal read access for log collection
  systemd.services.alloy.serviceConfig = {
    SupplementaryGroups = [ "systemd-journal" ];
  };

  # Prometheus node exporter for system metrics
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    port = 9100;
  };
  networking.firewall.allowedTCPPorts = [ 9100 ];
}
