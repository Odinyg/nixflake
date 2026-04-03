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

  # Work
  crypt.enable = true;

  # Laptop-specific services
  services = {
    playerctld.enable = true;
  };

  # Terminal opacity for battery life
  styling.opacity.terminal = 0.92;
  styling.cursor.size = 18;
}
