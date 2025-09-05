{
  config,
  pkgs,
  lib,
  ...
}:
{
  # ==============================================================================
  # ARCH BASE HOME-MANAGER CONFIGURATION
  # This profile contains only Home Manager compatible options for Arch Linux
  # System-level services are managed by Arch/systemd, not Nix
  # ==============================================================================

  # ==============================================================================
  # TERMINAL & CLI TOOLS (All Home Manager compatible)
  # ==============================================================================
  neovim.enable = true;
  zsh.enable = true;
  kitty.enable = true;
  termUtils.enable = true;
  zellij.enable = true;

  # ==============================================================================
  # DEVELOPMENT TOOLS (Home Manager modules)
  # ==============================================================================
  git.enable = true;
  direnv.enable = true;

  # ==============================================================================
  # DESKTOP APPLICATIONS (Home Manager installable)
  # ==============================================================================
  thunar.enable = true;
  chromium.enable = true;
  discord.enable = true;

  # ==============================================================================
  # DESKTOP CONFIGS (Config files only, not packages)
  # ==============================================================================
  rofi.enable = true;      # Rofi launcher config (package via Arch)
  fonts.enable = true;     # Font packages and config

  # ==============================================================================
  # WORK MODULES (Home Manager compatible)
  # ==============================================================================
  _1password.enable = true;
  work.enable = true;

  # ==============================================================================
  # USER UTILITIES (Home Manager compatible)
  # ==============================================================================
  utils.enable = true;  # User-level utilities
  xdg.enable = true;   # XDG config (user-level)

  # ==============================================================================
  # THEME CONFIGURATION (Stylix works with Home Manager)
  # ==============================================================================
  styling.enable = true;
  styling.theme = lib.mkDefault "nord";
  styling.polarity = lib.mkDefault "dark";
  styling.opacity.terminal = lib.mkDefault 0.90;
  styling.cursor.size = lib.mkDefault 20;
  styling.autoEnable = lib.mkDefault true;

  # ==============================================================================
  # HOME MANAGER SPECIFIC SETTINGS
  # ==============================================================================
  home-manager.backupFileExtension = "backup-$(date +%Y%m%d_%H%M%S)";

  # ==============================================================================
  # ARCH PACKAGE MANAGEMENT BASE
  # ==============================================================================
  archPackages = {
    enable = true;
    # Common packages are defined in arch-packages.nix
    # Machine-specific packages are added in arch-laptop.nix
  };

  # ==============================================================================
  # NOTES ON SYSTEM SERVICES (Managed by Arch, not Nix)
  # ==============================================================================
  # The following are managed by Arch systemd, not Home Manager:
  # - Hyprland (Wayland compositor)
  # - NetworkManager (networking)
  # - Bluetooth (bluez)
  # - Audio (pipewire/pulseaudio)
  # - Printing (CUPS)
  # - Tailscale
  # - Syncthing
  # - Docker
  # - libvirt/QEMU
  # - Firewall (iptables/nftables)
  # - fail2ban
  # - avahi
  # - polkit
  # 
  # Install these via arch-packages.nix or manually with pacman
  # Enable them with: sudo systemctl enable --now <service>
}