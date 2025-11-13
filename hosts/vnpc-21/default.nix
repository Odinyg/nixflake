{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix
    ../../profiles/hardware/nvidia.nix
  ];

  # ==============================================================================
  # BOOT CONFIGURATION
  # ==============================================================================
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ==============================================================================
  # NETWORKING
  # ==============================================================================
  networking.hostName = "VNPC-21";
  networking.networkmanager = {
    enable = true;
    unmanaged = [ ];
  };

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.extraGroups.vboxusers.members = [ "odin" ];
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "odin";
    extraGroups =
      [ "lp" "scanner" "docker" "networkmanager" "wheel" "plugdev" ];
    packages = with pkgs; [
      rclone
      insync
      tree
      libva-utils
      mesa-demos
      vulkan-tools
      wayland-utils
      vesktop
      kdePackages.kate
      screen
      shutter
    ];
  };

  # ==============================================================================
  # HARDWARE - NVIDIA GPU
  # ==============================================================================
  hardware.nvidia-gpu.enable = true;

  # ==============================================================================
  # HOST-SPECIFIC OVERRIDES
  # ==============================================================================
  # Desktop environments
  hyprland = {
    enable = true;

    # Kanshi display profiles for dynamic monitor configuration
    kanshi.profiles = [
      # External triple monitor setup
      {
        profile.name = "external-monitors";
        profile.outputs = [
          {
            criteria = "eDP-1";
            position = "0,0";
            scale = 1.25;
          }
          {
            criteria = "DP-4";
            mode = "2560x1440";
            position = "1536,0";
          }
          {
            criteria = "DP-5";
            mode = "2560x1440";
            position = "4096,0";
          }
        ];
      }
      # Laptop screen only
      {
        profile.name = "vnpc-21-only";
        profile.outputs = [{
          criteria = "eDP-1";
          status = "enable";
          mode = "1920x1080";
          scale = 1.0;
        }];
      }
    ];

    # Hyprland workspace assignments
    monitors.extraConfig = ''
      # VNPC-21: Triple monitor workspace setup
      workspace = 1, monitor:DP-4, default:true
      workspace = 2, monitor:DP-4
      workspace = 3, monitor:DP-4
      workspace = 4, monitor:DP-4
      workspace = 5, monitor:DP-4

      workspace = 6, monitor:DP-5, default:true
      workspace = 7, monitor:DP-5
      workspace = 8, monitor:DP-5

      workspace = 9, monitor:HDMI-A-1
      workspace = 0, monitor:HDMI-A-1
    '';
  };

  programs.kdeconnect.enable = true;

  # Secrets management
  secrets.enable = true;

  # Work tools
  onedrive.enable = false;

  # Terminal multiplexer
  zellij.enable = true;

  # Network sharing
  init-net.enable = true;

  # Hosted services
  hosted-services.n8n.enable = true;

  # ==============================================================================
  # DISTRIBUTED BUILDS - USE STATION AS BUILDER
  # ==============================================================================
  distributedBuilds = {
    enable = true;
    isBuilder = false;
  };

  # ==============================================================================
  # SERVICES
  # ==============================================================================
  # Printing drivers
  services.printing.drivers = with pkgs; [
    brgenml1lpr
    brgenml1cupswrapper
    ptouch-driver
    gutenprint
    cups-filters
    ghostscript
  ];

  # SSH configuration
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };

  # ==============================================================================
  # SYSTEM PACKAGES
  # ==============================================================================
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    pciutils
    system-config-printer
    lshw
    tailscale
    ptouch-driver
  ];

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}
