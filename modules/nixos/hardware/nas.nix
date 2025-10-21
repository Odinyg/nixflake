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
    services.samba.enable = true;
    fileSystems."/mnt/smb" = {
      device = "//192.168.1.153/server_new_media";
      fsType = "cifs";
            options = [ 
        "credentials=/etc/nixos/smb-secrets" #TODO NOT WORKING WITH FILE BUT PASSWORD STRAIGHT IN OPTIONS WORKS I WILL COME BACK TO THIS WHEN I ADD SOPS
        "vers=2.0"
        "file_mode=0777"
        "dir_mode=0777"
      ];
    };
    
    environment.systemPackages = [
      pkgs.cifs-utils
    ];
    boot.kernelModules = [ "cifs" ];
  };
}
