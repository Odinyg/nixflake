{ config, pkgs, lib, inputs, ... }:
{
  # ==============================================================================
  # ARCH LINUX HOME-MANAGER CONFIGURATION EXAMPLE
  # ==============================================================================
  # This configuration is for standalone home-manager on Arch Linux
  # System-level configuration is managed by Arch Linux itself
  # ==============================================================================

  imports = [
    ../../profiles/home-manager/base.nix
  ];

  # ==============================================================================
  # USER INFORMATION
  # ==============================================================================
  home.username = "youruser";
  home.homeDirectory = "/home/youruser";
  home.stateVersion = "25.05";

  # Enable home-manager
  programs.home-manager.enable = true;

  # ==============================================================================
  # DESKTOP ENVIRONMENT
  # ==============================================================================
  # Enable Hyprland configuration (Hyprland itself must be installed via pacman)
  hyprland.enable = true;

  # ==============================================================================
  # TERMINAL & CLI TOOLS
  # ==============================================================================
  neovim.enable = true;
  zsh.enable = true;
  prompt.enable = true;
  kitty.enable = true;
  zellij.enable = true;
  system-tools.enable = true;

  # ==============================================================================
  # DEVELOPMENT TOOLS
  # ==============================================================================
  git.enable = true;
  direnv.enable = true;
  languages.enable = true;

  # ==============================================================================
  # DESKTOP APPLICATIONS
  # ==============================================================================
  thunar.enable = true;
  chromium.enable = true;
  discord.enable = true;

  # ==============================================================================
  # UTILITIES
  # ==============================================================================
  # Note: Some utilities like tailscale need to be installed system-wide via pacman
  # This only installs user-level tools
  xdg.enable = true;
  
  # Application Categories
  kubernetes.enable = true;
  development.enable = true;
  media.enable = true;
  security.enable = true;
  communication.enable = true;
  utilities.enable = true;

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
  # ADDITIONAL USER PACKAGES
  # ==============================================================================
  home.packages = with pkgs; [
    # Add any additional packages you want managed by Nix
    tree
    htop
    ripgrep
    fd
  ];

  # ==============================================================================
  # NOTES FOR ARCH LINUX USERS
  # ==============================================================================
  # 1. Install Nix package manager first:
  #    sh <(curl -L https://nixos.org/nix/install) --daemon
  #
  # 2. Enable flakes in ~/.config/nix/nix.conf:
  #    experimental-features = nix-command flakes
  #
  # 3. Install home-manager:
  #    nix run home-manager/master -- init --switch
  #
  # 4. Clone this repository and build:
  #    git clone https://github.com/Odinyg/nixflake.git
  #    cd nixflake
  #    home-manager switch --flake .#youruser@yourhostname
  #
  # 5. System-level services (audio, bluetooth, networking) are managed by Arch
  #    Install them with pacman:
  #    - sudo pacman -S pipewire pipewire-pulse wireplumber
  #    - sudo pacman -S bluez bluez-utils
  #    - sudo pacman -S networkmanager
  #
  # 6. For Hyprland, install via pacman:
  #    sudo pacman -S hyprland
  #
  # 7. Enable required systemd services:
  #    systemctl --user enable pipewire pipewire-pulse wireplumber
  #    sudo systemctl enable bluetooth
  #    sudo systemctl enable NetworkManager
}
