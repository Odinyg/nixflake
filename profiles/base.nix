{ config, ... }:
{
  # ==============================================================================
  # CORE SYSTEM CONFIGURATION — shared by all desktop profiles
  # ==============================================================================

  # Nix configuration
  services.envfs.enable = true;
  # Clean up stale .hm-backup files before home-manager activation so backups
  # from a previous generation don't block the current one.
  system.activationScripts.cleanupHmBackups = {
    text = ''
      find /home -name '*.hm-backup' -delete 2>/dev/null || true
    '';
    deps = [ ];
  };
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
    warn-dirty = false;
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
