{
  config,
  pkgs,
  lib,
  ...
}:
{
  # ==============================================================================
  # CORE SYSTEM CONFIGURATION — shared by all desktop profiles
  # ==============================================================================

  # Nix configuration
  services.envfs.enable = true;
  home-manager.backupFileExtension = "backup-$(date +%Y%m%d_%H%M%S)";

  # Networking
  networking.firewall.enable = true;

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      config.user
    ];
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
