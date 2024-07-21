{ lib, config, ... }:
{
  options = {
    virt-man = {
      enable = lib.mkEnableOption {
        description = "Enable virt man";
        default = false;
      };
    };
  };
  config = lib.mkIf config.virt-man.enable {

    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    virtualisation.libvirtd.qemu = {
      swtpm.enable = true;
      ovmf.enable = true;
    };
    virtualisation.spiceUSBRedirection.enable = true;

  };
}
