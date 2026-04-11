{ config, ... }:
{
  # ==============================================================================
  # CORE SYSTEM CONFIGURATION — shared by all desktop profiles
  # ==============================================================================

  # Nix configuration
  services.envfs.enable = true;
  # Home Manager treats this as a literal suffix, so use a unique stable suffix
  # instead of shell substitution that never executes during activation.
  home-manager.backupFileExtension = "hm-backup";

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
