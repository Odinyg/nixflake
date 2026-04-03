{
  config,
  lib,
  ...
}:
let
  cfg = config.server.nfs;
in
{
  options.server.nfs = {
    enable = lib.mkEnableOption "NFS client with TrueNAS mounts";
  };

  config = lib.mkIf cfg.enable {
    # NFS client support
    boot.supportedFilesystems = [ "nfs" ];

    # NAS NFS mounts — matches current /etc/fstab entries
    # Default: noauto + x-systemd.automount (mount on first access)
    # Hosts that need mounts override options with lib.mkForce to remove noauto

    fileSystems."/mnt/nas/media" = {
      device = "10.10.10.20:/mnt/big/media";
      fsType = "nfs";
      options = [
        "defaults"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "_netdev"
        "noauto"
      ];
    };

    fileSystems."/mnt/nas/downloads" = {
      device = "10.10.10.20:/mnt/medium/downloads";
      fsType = "nfs";
      options = [
        "defaults"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "_netdev"
        "noauto"
      ];
    };

    fileSystems."/mnt/nas/backups" = {
      device = "10.10.10.20:/mnt/medium/backups";
      fsType = "nfs";
      options = [
        "defaults"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "_netdev"
        "noauto"
      ];
    };

    fileSystems."/mnt/nas/movies" = {
      device = "10.10.10.20:/mnt/medium/movies";
      fsType = "nfs";
      options = [
        "defaults"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "_netdev"
        "noauto"
      ];
    };
  };
}
