{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
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

  boot.kernel.sysctl."net.ipv4.ip_forwarding" = 1;

  # ==============================================================================
  # NETWORKING
  # ==============================================================================
  networking.hostName = "VNPC-21";
  networking.networkmanager = {
    enable = true;
    unmanaged = [ ];
  };

  # ==============================================================================
  # LOCALIZATION
  # ==============================================================================
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.extraGroups.vboxusers.members = [ "odin" ];
  programs.zsh.enable = true;
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "odin";
    extraGroups = [
      "lp"
      "scanner"
      "docker"
      "networkmanager"
      "wheel"
      "plugdev"
    ];
    packages = with pkgs; [
      rclone
      insync
      kdePackages.kdeconnect-kde
      firefox
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

  # Work tools
  onedrive.enable = false;

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
  # PROGRAMS
  # ==============================================================================
  services.envfs.enable = true;

  # ==============================================================================
  # SERVICES
  # ==============================================================================
  # Printing drivers
  services.printing.drivers = with pkgs; [
    brlaser
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
    libusb1
  ];

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}
