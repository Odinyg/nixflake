{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./base.nix ];

  # ==============================================================================
  # LAPTOP-SPECIFIC CONFIGURATION
  # ==============================================================================

  # Hardware for mobile systems
  randr.enable = false;

  # Work
  crypt.enable = true;

  # Laptop-specific services
  services = {
    flatpak.enable = true;
    playerctld.enable = true;
  };

  # Terminal opacity for battery life
  styling.opacity.terminal = 0.92;
  styling.cursor.size = 18;
}