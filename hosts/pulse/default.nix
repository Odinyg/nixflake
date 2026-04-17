{
  mkServerNetwork,
  inventory,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    (mkServerNetwork {
      ip = inventory.pulse;
      gateway = "10.10.30.1";
    })
  ];

  networking.hostName = "pulse";

  # --- Services ---
  server.disko.enable = true;

  server.prometheus.enable = true;
  server.loki.enable = true;
  server.grafana.enable = true;
  server.gatus.enable = true;
  server.ntfy.enable = true;

  system.stateVersion = "25.05";
}
