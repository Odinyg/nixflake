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

  # Gaming
  gaming.enable = lib.mkDefault false;

  # Additional services for desktop systems
  services.acpid.enable = true;
}