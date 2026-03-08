{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "sugar";

  # TODO: Phase 2 — self-hosted apps (native + OCI containers)

  sops.defaultSopsFile = ../../secrets/sugar.yaml;

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
