{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./desktop.nix ];

  # ==============================================================================
  # WORKSTATION-SPECIFIC CONFIGURATION
  # ==============================================================================

  # Additional desktop environments
  bspwm.enable = lib.mkDefault false;
  randr.enable = lib.mkDefault true;
  programs.kdeconnect.enable = lib.mkDefault false;

  # Work tools
  onedrive.enable = lib.mkDefault false;
  programs.dconf.enable = true;


  # Enhanced printing with additional drivers
  services.printing = {
    logLevel = "debug";
    openFirewall = true;
  };


}