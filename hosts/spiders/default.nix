{ lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "spiders";

  # Static IP — Cantabo VPS
  networking.useDHCP = false;
  networking.enableIPv6 = lib.mkForce true;
  networking.interfaces.eth0 = {
    ipv4.addresses = [
      {
        address = "95.111.255.104";
        prefixLength = 20;
      }
    ];
    ipv6.addresses = [
      {
        address = "2a02:c207:2318:6493::1";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway = {
    address = "95.111.240.1";
    interface = "eth0";
  };
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };
  networking.nameservers = [
    "213.136.95.10"
    "213.136.95.11"
    "2a02:c207::1:53"
  ];

  sops.defaultSopsFile = ../../secrets/spiders.yaml;

  # --- Services ---
  server.disko.enable = true;
  server.disko.disk = "/dev/sda";
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
