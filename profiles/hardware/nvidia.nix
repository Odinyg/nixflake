{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    hardware.nvidia-gpu = {
      enable = lib.mkEnableOption {
        description = "Enable NVIDIA GPU support with prime and optimizations";
        default = false;
      };
      
      prime = {
        nvidiaBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:1:0:0";
          description = "NVIDIA GPU PCI Bus ID";
        };
        
        intelBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:0:2:0";
          description = "Intel GPU PCI Bus ID";
        };
      };
    };
  };

  config = lib.mkIf config.hardware.nvidia-gpu.enable {
    # NVIDIA drivers
    services.xserver.videoDrivers = [ "nvidia" ];
    
    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      modesetting.enable = true;
      powerManagement.enable = false;
      open = true;
      nvidiaSettings = true;
      prime.sync.enable = true;
      prime.nvidiaBusId = config.hardware.nvidia-gpu.prime.nvidiaBusId;
      prime.intelBusId = config.hardware.nvidia-gpu.prime.intelBusId;
    };

    # Environment variables for NVIDIA
    environment.variables = {
      GBM_BACKEND = "nvidia-drm";
      WLR_DRM_DEVICES = "$HOME/.config/hypr/card:$HOME/.config/hypr/otherCard";
      WLR_NO_HARDWARE_CURSORS = "1";
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NIXOS_OZONE_WL = "1";
    };

    # Kernel parameters for NVIDIA
    boot.kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia_drm.fbdev=1"
      "fbdev=1"
    ];

    # Enable 32-bit graphics for gaming/compatibility
    hardware.graphics.enable32Bit = true;
  };
}