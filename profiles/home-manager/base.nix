{ config, pkgs, lib, ... }:
{
  # ==============================================================================
  # BASE HOME-MANAGER CONFIGURATION
  # ==============================================================================
  # This profile provides a base configuration for home-manager standalone
  # Suitable for non-NixOS systems like Arch Linux
  # ==============================================================================

  # Import nixvim module for Neovim configuration
  imports = [ ];

  # ==============================================================================
  # TERMINAL & CLI TOOLS
  # ==============================================================================
  neovim.enable = lib.mkDefault true;
  zsh.enable = lib.mkDefault true;
  prompt.enable = lib.mkDefault true;
  kitty.enable = lib.mkDefault true;
  system-tools.enable = lib.mkDefault true;

  # ==============================================================================
  # DEVELOPMENT TOOLS
  # ==============================================================================
  git.enable = lib.mkDefault true;
  direnv.enable = lib.mkDefault true;
  languages.enable = lib.mkDefault true;

  # ==============================================================================
  # DESKTOP APPLICATIONS
  # ==============================================================================
  thunar.enable = lib.mkDefault true;
  chromium.enable = lib.mkDefault true;

  # ==============================================================================
  # UTILITIES
  # ==============================================================================
  xdg.enable = lib.mkDefault true;
  
  # Application Categories
  development.enable = lib.mkDefault true;
  utilities.enable = lib.mkDefault true;

  # ==============================================================================
  # THEME CONFIGURATION
  # ==============================================================================
  styling.enable = lib.mkDefault true;
  styling.theme = lib.mkDefault "nord";
  styling.polarity = lib.mkDefault "dark";
  styling.opacity.terminal = lib.mkDefault 0.90;
  styling.cursor.size = lib.mkDefault 20;
  styling.autoEnable = lib.mkDefault true;

  # ==============================================================================
  # NIX CONFIGURATION
  # ==============================================================================
  # These settings only affect the user's Nix behavior
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  # ==============================================================================
  # SESSION VARIABLES
  # ==============================================================================
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
