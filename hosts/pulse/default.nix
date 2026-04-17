{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "pulse";

  # Static IP
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.30.112";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.10.30.1";
    nameservers = [
      "10.10.30.1"
      "1.1.1.1"
    ];
  };

  # --- Services ---
  server.disko.enable = true;

  server.prometheus.enable = true;
  server.loki.enable = true;
  server.grafana.enable = true;
  server.gatus.enable = true;
  server.ntfy.enable = true;

  system.stateVersion = "25.05";
}
