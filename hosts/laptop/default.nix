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
    ../../profiles/laptop.nix
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
  networking.hostName = "laptop";

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [
      "networkmanager"
      "plugdev"
      "wheel"
    ];
  };

  # ==============================================================================
  # HOST-SPECIFIC OVERRIDES
  # ==============================================================================
  gaming.enable = true;
  crypt.enable = true;
  
  # ==============================================================================
  # DISTRIBUTED BUILDS - USE STATION AS BUILDER
  # ==============================================================================
  distributedBuilds = {
    enable = true;
    isBuilder = false;
  };
  
  # Cursor customization
  styling.cursor.package = pkgs.bibata-cursors;
  styling.cursor.name = "Bibata-Modern-Ice";

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}