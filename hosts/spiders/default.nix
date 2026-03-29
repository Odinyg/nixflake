{ ... }:

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
  # UDP ports (STUN/TURN) are opened automatically by coturn module
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
    22
  ];

  system.stateVersion = "25.05";
}
