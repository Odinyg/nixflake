{
  config,
  pkgs,
  lib,
  ...
}:
{
  # ==============================================================================
  # COMMON CONFIGURATION FOR ALL HOSTS
  # ==============================================================================

  # Nix configuration
  services.envfs.enable = true;
  home-manager.backupFileExtension = "backup-$(date +%Y%m%d_%H%M%S)";
  
  # Networking
  networking.firewall.enable = true;

  # ==============================================================================
  # DESKTOP ENVIRONMENT & DISPLAY
  # ==============================================================================
  general.enable = true;
  hyprland.enable = true;
  fonts.enable = true;

  # ==============================================================================
  # HARDWARE MODULES
  # ==============================================================================
  audio.enable = true;
  wireless.enable = true;
  bluetooth.enable = true;
  zsa.enable = true;

  # ==============================================================================
  # TERMINAL & CLI TOOLS
  # ==============================================================================
  neovim.enable = true;
  zsh.enable = true;
  prompt.enable = true;
  kitty.enable = true;
  tmux.enable = true;
  system-tools.enable = true;

  # ==============================================================================
  # DEVELOPMENT TOOLS
  # ==============================================================================
  git.enable = true;
  direnv.enable = true;
  languages.enable = true;

  # Development packages needed for building C/C++ projects
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    pkg-config
    libusb1
  ];

  # ==============================================================================
  # DESKTOP APPLICATIONS
  # ==============================================================================
  thunar.enable = true;
  chromium.enable = true;
  zen-browser.enable = true;
  discord.enable = true;

  # ==============================================================================
  # WORK MODULES
  # ==============================================================================
  _1password.enable = true;
  work.enable = true;

  # ==============================================================================
  # SYSTEM UTILITIES
  # ==============================================================================
  fail2ban-security.enable = lib.mkDefault true;
  tailscale.enable = true;
  syncthing.enable = true;
  polkit.enable = true;
  xdg.enable = true;

  # Application Categories (split from old utils.nix)
  kubernetes.enable = true;
  development.enable = true;
  media.enable = true;
  security.enable = true;
  communication.enable = true;
  utilities.enable = true;

  # ==============================================================================
  # VIRTUALIZATION
  # ==============================================================================
  virtualization = {
    enable = true;
    docker.rootless = false;
    qemu.virt-manager = true;
    virtualbox.enable = false;
  };

  # ==============================================================================
  # THEME CONFIGURATION
  # ==============================================================================
  styling.enable = true;
  styling.theme = lib.mkDefault "nord";
  styling.polarity = lib.mkDefault "dark";
  styling.opacity.terminal = lib.mkDefault 0.90;
  styling.cursor.size = lib.mkDefault 20;
  styling.autoEnable = lib.mkDefault true;

  # ==============================================================================
  # SYSTEM SERVICES
  # ==============================================================================
  services = {
    gvfs.enable = true;
    locate.enable = true;
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  # ==============================================================================
  # NIX CONFIGURATION
  # ==============================================================================
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      config.user
    ];
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}