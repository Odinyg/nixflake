{ config, pkgs, lib, ... }: {
  options = {
    nvidia-gpu = {
      enable = lib.mkEnableOption {
        description = "Enable NVIDIA GPU support for desktop systems";
        default = false;
      };
    };
  };

  config = lib.mkIf config.nvidia-gpu.enable {
    # Allow unfree packages for NVIDIA drivers
    nixpkgs.config.allowUnfree = true;

    # NVIDIA drivers
    services.xserver.videoDrivers = [ "nvidia" ];

    # Hardware graphics support (renamed from hardware.opengl in NixOS 24.11+)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ nvidia-vaapi-driver libva egl-wayland ];
    };

    # NVIDIA configuration optimized for RTX 3090 desktop
    hardware.nvidia = {
      # Use open-source kernel modules (recommended for Ampere architecture)
      open = true;

      # Enable modesetting (required for Wayland)
      modesetting.enable = true;

      # Power management (set to false for desktop RTX 3090)
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      # Enable NVIDIA settings GUI
      nvidiaSettings = true;

      # Use stable driver (555+ recommended for explicit sync support)
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Environment variables for NVIDIA with Hyprland
    environment.variables = {
      # Essential NVIDIA variables
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_MaxFramesAllowed = "1";
      NVD_BACKEND = "direct";

      # Session and compatibility
      XDG_SESSION_TYPE = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";

      # GTK and Qt Wayland support
      GDK_BACKEND = "wayland,x11,*";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
    };

    # Kernel parameters for NVIDIA
    boot.kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      # Disable DPMS to prevent DisplayPort wake issues
      "nvidia.NVreg_RegistryDwords=PowerMizerEnable=0x1;PerfLevelSrc=0x2222"
    ];

    # Early loading of NVIDIA modules
    boot.initrd.kernelModules =
      [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

    boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

    # System packages for NVIDIA support
    environment.systemPackages = with pkgs; [
      libva
      egl-wayland
      nvidia-vaapi-driver
    ];

    # Enable suspend services for NVIDIA
    systemd.services = {
      nvidia-suspend.enable = true;
      nvidia-hibernate.enable = true;
      nvidia-resume.enable = true;
    };
  };
}

