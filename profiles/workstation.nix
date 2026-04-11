{ ... }:
{
  imports = [ ./desktop.nix ];

  # ==============================================================================
  # WORKSTATION-SPECIFIC CONFIGURATION
  # ==============================================================================

  # Work tools
  programs.dconf.enable = true;

  # Enhanced printing with additional drivers
  services.printing = {
    logLevel = "debug";
    openFirewall = true;
  };

}
