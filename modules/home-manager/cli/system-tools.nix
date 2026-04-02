{
  config,
  pkgs,
  lib,
  options,
  ...
}:
let
  standalone = !(options ? nixpkgs);
  hmConfig = {
    home.packages = with pkgs; [
      # System Monitoring
      btop # Resource monitor (better top)

      # Search & Text Processing
      ripgrep-all # Search tool with support for PDFs, office docs, etc.
      jq # JSON processor

      # Version Control UI
      gitui # Terminal UI for git

      # Network & Security
      dnsutils # DNS utilities (dig, nslookup)
      sshpass # Non-interactive SSH password auth
      keychain

      # System Utilities
      usbutils # USB device utilities (lsusb)
      bc # Calculator

      # File Management
      trash-cli # FreeDesktop trash (safe rm replacement)

      # Log Analysis & Debugging
      lnav # Interactive log navigator with SQL queries
      tailspin # Auto-colorizing log tail (replaces tail -f)
      moreutils # ts (timestamps), sponge, and other unix gems
    ];

    # Convenient shell aliases
    home.shellAliases = {
      top = "btop"; # Use btop instead of top
    };
  };
in
{
  options = {
    system-tools = {
      enable = lib.mkEnableOption "system monitoring and CLI utilities";
    };
  };

  config = lib.mkMerge (
    [
      {
        home-manager.users.${config.user} = lib.mkIf config.system-tools.enable hmConfig;
      }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.system-tools.enable hmConfig)
    ]
  );
}
