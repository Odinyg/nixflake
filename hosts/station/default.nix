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
    ../../profiles/desktop.nix
  ];

  # ==============================================================================
  # BOOT CONFIGURATION
  # ==============================================================================
  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    useOSProber = true;
  };

  # ==============================================================================
  # NETWORKING
  # ==============================================================================
  networking.hostName = "station";

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
    ];
  };

  # ==============================================================================
  # SECURITY - SOPS
  # ==============================================================================
  sops.defaultSopsFile = ./../../secrets/general.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = /home/none/.config/sops/age/keys.txt;

  # ==============================================================================
  # HARDWARE - NVIDIA GPU
  # ==============================================================================
  nvidia-gpu.enable = true;

  # ==============================================================================
  # DISTRIBUTED BUILDS - BUILD SERVER
  # ==============================================================================
  distributedBuilds = {
    enable = true;
    isBuilder = true;
  };

  # ==============================================================================
  # PROGRAMS
  # ==============================================================================
  services.envfs.enable = true;

  # ==============================================================================
  # HOST-SPECIFIC OVERRIDES
  # ==============================================================================
  # Gaming
  gaming = {
    enable = true;
    launchers = {
      heroic = true;
      bottles = true;
    };
  };
  
  # Encryption tools
  crypt.enable = true;
  
  # Terminal opacity
  styling.opacity.terminal = 0.85;

  # ==============================================================================
  # SYSTEM PACKAGES
  # ==============================================================================
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.system}".default
    libusb1
  ];

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}