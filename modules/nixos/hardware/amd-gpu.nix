{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.amd-gpu;
in
{
  options = {
    amd-gpu = {
      enable = lib.mkEnableOption "AMD graphics configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    boot.kernelParams = [
      "amd_pstate=active"
      "amdgpu.dc=1"
    ];
  };
}
