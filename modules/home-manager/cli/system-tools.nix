{ config, pkgs, lib, ... }: {

  options = {
    system-tools = {
      enable = lib.mkEnableOption {
        description = "Enable system monitoring and CLI utilities";
        default = false;
      };
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

      # MCP Server
      mcp-nixos          # NixOS MCP server for Claude Code
    ];

    # Convenient shell aliases
    home.shellAliases = {
      top = "btop";      # Use btop instead of top
    };
  };
}
