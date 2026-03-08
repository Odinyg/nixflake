{ config, lib, ... }:

{
  options.server.disk = lib.mkOption {
    type = lib.types.str;
    default = "/dev/vda";
    description = "Primary disk device for disko partitioning";
  };

  config.disko.devices.disk.main = {
    type = "disk";
    device = config.server.disk;
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
}
