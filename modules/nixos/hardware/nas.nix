{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.smbmount;
in
{
  options = {
    smbmount = {
      enable = lib.mkEnableOption "SMB mount";
      share = lib.mkOption {
        type = lib.types.str;
        default = "//192.168.1.153/server_new_media";
        description = "SMB share path to mount";
      };
      mountPoint = lib.mkOption {
        type = lib.types.str;
        default = "/mnt/smb";
        description = "Local mount point for the SMB share";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    # Enable secrets management for SMB credentials
    secrets.enable = true;

    services.samba.enable = true;
    fileSystems.${cfg.mountPoint} = {
      device = cfg.share;
      fsType = "cifs";
      options = [
        "credentials=/etc/nixos/smb-secrets"
        "vers=2.0"
        "file_mode=0755"
        "dir_mode=0755"
        "x-systemd.automount"
        "x-systemd.requires=network-online.target"
      ];
    };

    environment.systemPackages = [
      pkgs.cifs-utils
    ];
    boot.kernelModules = [ "cifs" ];
  };
}
