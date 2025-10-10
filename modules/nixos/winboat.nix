{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  options = {
    winboat = {
      enable = lib.mkEnableOption {
        description = "Enable WinBoat - Run Windows apps on Linux";
        default = false;
      };
    };
  };

  config = lib.mkIf config.winboat.enable {
    # Winboat package
    environment.systemPackages = with pkgs; [
      inputs.winboat.packages.x86_64-linux.winboat
      freerdp3
      docker-compose
    ];

    # Ensure required kernel modules are loaded
    boot.kernelModules = [
      "iptable_nat"
    ];

    # Ensure virtualization is enabled (KVM/libvirtd)
    assertions = [
      {
        assertion = config.virtualisation.docker.enable;
        message = "WinBoat requires Docker to be enabled. Set virtualisation.docker.enable = true;";
      }
      {
        assertion = config.virtualisation.libvirtd.enable;
        message = "WinBoat requires libvirtd/KVM to be enabled. Set virtualisation.libvirtd.enable = true;";
      }
    ];
  };
}
