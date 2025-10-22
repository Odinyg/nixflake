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
      glxinfo
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
  hyprland.enable = true;
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

  # Virtualization tools
  winboat.enable = true;

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
    inputs.zen-browser.packages."${pkgs.system}".default
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
