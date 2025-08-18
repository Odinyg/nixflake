{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
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
  # DESKTOP ENVIRONMENT & DISPLAY
  # ==============================================================================
  # XDG Desktop Portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # ==============================================================================
  # CUSTOM MODULE CONFIGURATION
  # ==============================================================================
  programs.nix-ld.enable = true;
  home-manager.backupFileExtension = "backup-$(date +%Y%m%d_%H%M%S)";
  # Desktop modules
  general.enable = true;
  hyprland.enable = true;
  rofi.enable = true;
  randr.enable = false;
  fonts.enable = true;

  # Hardware modules
  audio.enable = true;
  wireless.enable = true;
  bluetooth.enable = true;
  zsa.enable = false;

  # Terminal & CLI tools
  neovim.enable = true;
  zsh.enable = true;
  tmux.enable = false;
  zellij.enable = true;
  kitty.enable = true;
  termUtils.enable = true;

  # Development tools
  git.enable = true;
  direnv.enable = true;

  # Desktop Apps
  discord.enable = true;
  thunar.enable = true;
  chromium.enable = true;
  programs.steam.enable = true;

  # Work
  _1password.enable = true;
  work.enable = true; # TODO Split into smaller and add/remove/move apps

  # System utilities
  crypt.enable = true;
  tailscale.enable = true;
  syncthing.enable = true;
  polkit.enable = true;
  utils.enable = true;
  xdg.enable = true;

  # Theme
  styling.enable = true;
  styling.theme = "nord";
  styling.polarity = "dark";
  styling.opacity.terminal = 0.92;
  styling.cursor.package = pkgs.bibata-cursors;
  styling.cursor.name = "Bibata-Modern-Ice";
  styling.cursor.size = 18;

  # ==============================================================================
  # SYSTEM SERVICES
  # ==============================================================================
  services = {
    flatpak.enable = true;
    gvfs.enable = true;
    locate.enable = true;
    printing.enable = true;
    playerctld.enable = true;
  };

  # ==============================================================================
  # NIX CONFIGURATION
  # ==============================================================================
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config = {
    permittedInsecurePackages = [
      "libsoup-2.74.3"
    ];
  };

  system.stateVersion = "25.05";
}
