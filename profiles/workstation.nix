{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./base.nix
    ./desktop.nix
  ];

  # ==============================================================================
  # WORKSTATION-SPECIFIC CONFIGURATION
  # ==============================================================================

  # Additional desktop environments
  randr.enable = lib.mkDefault true;
  
  # Work tools
  programs.dconf.enable = true;

  # Enhanced printing with additional drivers
  services.printing = {
    logLevel = "debug";
    openFirewall = true;
  };


}