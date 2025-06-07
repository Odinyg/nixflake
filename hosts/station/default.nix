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
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/nvme0n1";
      useOSProber = true;
    };
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
  sops.defaultSopsFile = ./../../secrets/general.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = /home/none/.config/sops/age/keys.txt;
  # ==============================================================================
  # DESKTOP ENVIRONMENT & DISPLAY
  # ==============================================================================
  amd-gpu.enable = true;

  # XDG Desktop Portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };
  # ==============================================================================
  # CUSTOM MODULE CONFIGURATION
  # ==============================================================================

  # Desktop modules
  programs.nix-ld.enable = true;
  home-manager.backupFileExtension = "backup-$(date +%Y%m%d_%H%M%S)";

  # Desktop modules
  general.enable = true;
  hyprland.enable = true;
  rofi.enable = true;
  fonts.enable = true;
  ollama.enable = false;

  # Hardware modules
  audio.enable = true;
  wireless.enable = true;
  zsa.enable = true;
  smbmount.enable = false;
  bluetooth.enable = true;

  # Terminal & CLI tools
  neovim.enable = true;
  zsh.enable = true;
  tmux.enable = false;
  kitty.enable = true;
  termUtils.enable = true;
  zellij.enable = true;

  # Development tools
  git.enable = true;
  direnv.enable = true;
  virtualization = {
    enable = true;
    qemu.virt-manager = true; # Disable virt-manager GUI
    remoteAccess.enable = true; # Disable Remmina
    virtualbox.enable = false; # Also enable VirtualBox
  };

  #  Desktop Apps
  discord.enable = true;
  thunar.enable = true;
  chromium.enable = true;
  gaming.enable = true;

  #  Work
  _1password.enable = false;
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
  styling.opacity.terminal = 0.85;
  styling.cursor.size = 20;
  styling.autoEnable = true;
  # ==============================================================================
  # SYSTEM SERVICES
  # ==============================================================================
  services = {
    syncthing.enable = true;
    gvfs.enable = true;
    locate.enable = true;
    acpid.enable = true;
  };
  system.stateVersion = "25.05";
}
