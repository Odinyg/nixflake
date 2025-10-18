{
  lib,
  config,
  pkgs,
  ...
}:
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

    virtualisation = {
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          runAsRoot = true;
          swtpm.enable = true;
        };
      };

    };
    programs.virt-manager.enable = true;
    services.spice-vdagentd.enable = true;
    environment.systemPackages = with pkgs; [
      virtiofsd
    ];

  };
}
