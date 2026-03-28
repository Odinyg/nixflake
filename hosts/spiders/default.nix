{ lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "spiders";

  # DHCP — VPS provider assigns IP
  networking.useDHCP = true;

  sops.defaultSopsFile = ../../secrets/spiders.yaml;

  # --- Services ---
  server.disko.enable = true;
  server.netbird.enable = true;
  server.netbird.domain = "netbird.pytt.io";

  # Firewall — VPS is public-facing, keep enabled
  networking.firewall.enable = lib.mkForce true;
  networking.firewall.allowedTCPPorts = [
    80
    443
    22
  ];
  networking.firewall.allowedUDPPorts = [ 3478 ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 49152;
      to = 65535;
    }
  ];

  system.stateVersion = "25.05";
}
