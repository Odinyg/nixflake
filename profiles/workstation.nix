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

  # Display management
  environment.systemPackages = [
    pkgs.xorg.xrandr
    pkgs.arandr
  ];
  services.autorandr.enable = true;

  # Work tools
  programs.dconf.enable = true;

  # Enhanced printing with additional drivers
  services.printing = {
    logLevel = "debug";
    openFirewall = true;
  };

}
