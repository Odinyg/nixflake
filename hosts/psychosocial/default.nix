{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "psychosocial";

  # Static IP — staging (change to 10.10.30.10 after cutover)
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.30.110";
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

  # TODO: Phase 4 — reverse proxy, auth, homepage (Caddy, Authelia, Homepage)

  # sops.defaultSopsFile = ../../secrets/psychosocial.yaml; # TODO: enable after encrypting secrets

  networking.firewall.allowedTCPPorts = [
    443 # Caddy HTTPS
    9959 # Authelia metrics
  ];

  system.stateVersion = "25.05";
}
