{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./base.nix ];

  # ==============================================================================
  # DESKTOP-SPECIFIC CONFIGURATION
  # ==============================================================================

  # Additional services for desktop systems
  services.acpid.enable = true;
}