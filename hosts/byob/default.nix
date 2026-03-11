{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  # Use unstable packages for ARR stack (Docker :latest tracks unstable)
  nixpkgs.overlays = [
    (final: prev: {
      sonarr = pkgs-unstable.sonarr;
      radarr = pkgs-unstable.radarr;
      prowlarr = pkgs-unstable.prowlarr;
      lidarr = pkgs-unstable.lidarr;
      nzbget = pkgs-unstable.nzbget;
      overseerr = pkgs-unstable.overseerr;
    })
  ];

  networking.hostName = "byob";

  # Static IP — staging (change to 10.10.50.10 after cutover)
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.50.110";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.10.50.1";
    nameservers = [
      "10.10.10.1"
      "1.1.1.1"
    ];
  };

  # sops.defaultSopsFile = ../../secrets/byob.yaml; # TODO: enable after encrypting secrets

  # NAS media mount — remove noauto to activate
  fileSystems."/mnt/nas/media".options = lib.mkForce [
    "defaults"
    "x-systemd.automount"
    "x-systemd.idle-timeout=600"
    "_netdev"
  ];

  # Local downloads disk (second VirtIO disk)
  fileSystems."/mnt/downloads" = {
    device = "/dev/vdb";
    fsType = "ext4";
    options = [ "defaults" ];
  };

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
  # Disable DynamicUser so we can manage data/permissions
  users.users.prowlarr = {
    isSystemUser = true;
    group = "media";
  };
  systemd.services.prowlarr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "prowlarr";
    Group = "media";
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
    settings = {
      MainDir = "/mnt/downloads";
      DestDir = "/mnt/downloads/complete";
      InterDir = "/mnt/downloads/incomplete";
      NzbDir = "/mnt/downloads/nzb";
      QueueDir = "/mnt/downloads/queue";
      TempDir = "/mnt/downloads/tmp";
      UnrarCmd = "${pkgs.unrar}/bin/unrar";
      SevenZipCmd = "${pkgs.p7zip}/bin/7za";
      CertStore = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
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
      download-dir = "/mnt/downloads/complete";
      incomplete-dir = "/mnt/downloads/incomplete";
      incomplete-dir-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
    };
  };
  systemd.services.transmission = {
    after = [ "mnt-downloads.mount" ];
    requires = [ "mnt-downloads.mount" ];
  };

  # Ensure download + media directories exist on boot
  systemd.tmpfiles.rules = [
    "d /mnt/downloads/complete 0775 transmission media -"
    "d /mnt/downloads/incomplete 0775 transmission media -"
    "d /mnt/downloads/nzb 0775 nzbget media -"
    "d /mnt/downloads/queue 0775 nzbget media -"
    "d /mnt/downloads/tmp 0775 nzbget media -"
    "d /mnt/downloads/scripts 0775 nzbget media -"
    "d /mnt/nas/media/tv 0775 root media -"
  ];

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
    image = "seerr/seerr:latest";
    environment = {
      TZ = "Europe/Oslo";
    };
    volumes = [ "/var/lib/homelab/seerr:/app/config" ];
    ports = [ "5055:5055" ];
  };

  system.stateVersion = "25.05";
}
