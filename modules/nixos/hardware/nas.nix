{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    smbmount = {
      enable = lib.mkEnableOption {
        description = "Enable SMB mount.";
        default = false;
      };
    };
  };
  config = lib.mkIf config.smbmount.enable {
    # Enable secrets management for SMB credentials
    secrets.enable = true;

    services.samba.enable = true;
    fileSystems."/mnt/smb" = {
      device = "//192.168.1.153/server_new_media";
      fsType = "cifs";
      options = [
        "credentials=/etc/nixos/smb-secrets"
        "vers=2.0"
        "file_mode=0777"
        "dir_mode=0777"
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
