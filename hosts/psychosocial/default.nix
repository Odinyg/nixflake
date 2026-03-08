{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "psychosocial";

  # TODO: Phase 4 — reverse proxy, auth, homepage (Caddy, Authelia, Homepage)

  sops.defaultSopsFile = ../../secrets/psychosocial.yaml;

  networking.firewall.allowedTCPPorts = [
    443 # Caddy HTTPS
    9959 # Authelia metrics
  ];

  system.stateVersion = "25.05";
}
