{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    hardware.nvidia-gpu = {
      enable = lib.mkEnableOption "NVIDIA GPU support with prime and optimizations";

      driverPackage = lib.mkOption {
        type = lib.types.enum [
          "stable"
          "beta"
          "latest"
          "production"
        ];
        default = "stable";
        description = "NVIDIA driver package to use (stable, beta, latest, or production)";
      };

      open = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use NVIDIA open-source kernel modules (false = proprietary)";
      };

      prime = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable NVIDIA PRIME sync (for laptops with hybrid graphics)";
        };

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
    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.${config.hardware.nvidia-gpu.driverPackage};
      modesetting.enable = true;
      powerManagement.enable = false;
      open = config.hardware.nvidia-gpu.open;
      nvidiaSettings = true;
      prime.sync.enable = config.hardware.nvidia-gpu.prime.enable;
      prime.nvidiaBusId = lib.mkIf config.hardware.nvidia-gpu.prime.enable config.hardware.nvidia-gpu.prime.nvidiaBusId;
      prime.intelBusId = lib.mkIf config.hardware.nvidia-gpu.prime.enable config.hardware.nvidia-gpu.prime.intelBusId;
    };

    # Environment variables for NVIDIA
    environment.variables = {
      GBM_BACKEND = "nvidia-drm";
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

    # Enable graphics with 32-bit support for gaming/Wine/Vulkan
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };
  };
}
