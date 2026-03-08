{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "sugar";

  # Static IP — staging (change to 10.10.30.11 after cutover)
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.30.111";
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

  # TODO: Phase 2 — self-hosted apps (native + OCI containers)

  # sops.defaultSopsFile = ../../secrets/sugar.yaml; # TODO: enable after encrypting secrets

  # Docker for OCI containers (perplexica, netboot, norish, myrlin, paseo, sparkyfitness)
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  virtualisation.oci-containers.backend = "docker";

  system.stateVersion = "25.05";
}
