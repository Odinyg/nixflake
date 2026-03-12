{ config, lib, ... }:
let
  cfg = config.server.disko;
in
{
  options.server.disko = {
    enable = lib.mkEnableOption "disko declarative disk partitioning";
    disk = lib.mkOption {
      type = lib.types.str;
      default = "/dev/vda";
      description = "Primary disk device for disko partitioning";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices.disk.main = {
      type = "disk";
      device = cfg.disk;
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # BIOS boot partition
          };
          esp = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
