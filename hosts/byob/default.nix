{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "byob";

  sops.defaultSopsFile = ../../secrets/byob.yaml;

  # Enable NAS mounts — remove noauto to activate
  fileSystems."/mnt/nas/media".options = lib.mkForce [
    "defaults"
    "x-systemd.automount"
    "x-systemd.idle-timeout=600"
    "_netdev"
  ];
  fileSystems."/mnt/nas/downloads".options = lib.mkForce [
    "defaults"
    "x-systemd.automount"
    "x-systemd.idle-timeout=600"
    "_netdev"
  ];

  # Shared media group — all ARR services + download clients use this
  # for NAS filesystem access
  users.groups.media = {
    gid = 1000;
  };

  # --- Sonarr ---
  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    settings = {
      server.port = 8989;
      log.analyticsEnabled = false;
      update.mechanism = "external";
    };
  };

  # --- Radarr ---
  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    settings = {
      server.port = 7878;
      log.analyticsEnabled = false;
      update.mechanism = "external";
    };
  };

  # --- Prowlarr ---
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings = {
      server.port = 9696;
      log.analyticsEnabled = false;
      update.mechanism = "external";
    };
  };

  # --- Lidarr ---
  services.lidarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    settings = {
      server.port = 8686;
      log.analyticsEnabled = false;
      update.mechanism = "external";
    };
  };

  # --- NZBGet ---
  services.nzbget = {
    enable = true;
    group = "media";
  };
  # NZBGet + Seerr don't have openFirewall options
  networking.firewall.allowedTCPPorts = [
    6789 # NZBGet
    5055 # Seerr
  ];

  # --- Transmission ---
  services.transmission = {
    enable = true;
    group = "media";
    openRPCPort = true;
    settings = {
      download-dir = "/mnt/nas/downloads/complete";
      incomplete-dir = "/mnt/nas/downloads/incomplete";
      incomplete-dir-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
    };
  };

  # --- Seerr (Overseerr replacement) ---
  # TODO: migrate to native NixOS service when seerr gets a module
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.seerr = {
    image = "seerrarr/seerr:latest";
    environment = {
      TZ = "Europe/Oslo";
    };
    volumes = [ "/var/lib/homelab/seerr:/app/config" ];
    ports = [ "5055:5055" ];
  };

  system.stateVersion = "25.05";
}
