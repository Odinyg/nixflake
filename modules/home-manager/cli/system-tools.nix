{ config, pkgs, lib, ... }: {

  options = {
    system-tools = {
      enable = lib.mkEnableOption "system monitoring and CLI utilities";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.system-tools.enable {
    home.packages = with pkgs; [
      # System Monitoring
      btop               # Resource monitor (better top)

      # Search & Text Processing
      ripgrep-all        # Search tool with support for PDFs, office docs, etc.
      jq                 # JSON processor

      # Version Control UI
      gitui              # Terminal UI for git

      # Network & Security
      sshpass            # Non-interactive SSH password auth

      # System Utilities
      usbutils           # USB device utilities (lsusb)
      bc                 # Calculator
    ];

    # Convenient shell aliases
    home.shellAliases = {
      top = "btop";      # Use btop instead of top
    };
  };
}
