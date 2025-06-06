{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    amd-gpu = {
      enable = lib.mkEnableOption {
        description = "Enable AMD graphics configuration";
        default = false;
      };
    };
  };

  config = lib.mkIf config.amd-gpu.enable {
    services.xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        rocmPackages.clr
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };

    boot.kernelParams = [
      "amd_pstate=active"
      "amdgpu.dc=1"
      "processor.max_cstate=1"
      "idle=poll"
      "mitigations=off"
    ];
  };
}
