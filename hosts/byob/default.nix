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

  # NAS mounts — remove noauto to activate
  fileSystems."/mnt/nas/media".options = lib.mkForce [
    "defaults"
    "x-systemd.automount"
    "x-systemd.idle-timeout=600"
    "_netdev"
  ];

  fileSystems."/mnt/nas/movies".options = lib.mkForce [
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

  # --- Services ---
  server.nfs.enable = true;
  server.disko.enable = true;
  server.arr.enable = true;
  server.nzbget.enable = true;
  server.transmission.enable = true;
  server.seerr.enable = true;

  # Media dirs on NAS
  systemd.tmpfiles.rules = [
    "d /mnt/nas/media/tvshows 0775 root media -"
  ];

  system.stateVersion = "25.05";
}
