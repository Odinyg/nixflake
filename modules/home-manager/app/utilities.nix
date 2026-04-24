{
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  lib,
  ...
}:
let
  cfg = config.utilities;
in
{

  options = {
    utilities = {
      enable = lib.mkEnableOption "miscellaneous utility applications";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    # Smart directory navigation
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    xdg.desktopEntries.win12-rdp = {
      name = "Win12 RDP";
      comment = "Connect to Windows via RDP";
      exec = "remmina -c /home/odin/.local/share/remmina/group_rdp_quick-connect_win12.remmina";
      icon = "remmina";
      terminal = false;
      categories = [
        "Network"
        "RemoteAccess"
      ];
    };

    home.packages = with pkgs; [
      # File Managers
      yazi # Terminal file manager

      # Image Viewers & Screenshot
      feh # Lightweight image viewer
      satty # Screenshot annotation

      # Archive Management
      xarchiver # Archive manager

      # Remote Access
      remmina # Remote desktop client
      freerdp # RDP client
      pkgs-unstable.rustdesk # Open-source remote desktop
      teamviewer # Remote desktop and support
      filezilla # FTP/SFTP client

      # System Utilities
      autokey # Automation tool
      xcape # Key modifier tool

      # X11 Utilities (for tdrop and window management)
      xorg.xwininfo # Window information utility
      xorg.xprop # Window properties

      # Printer Drivers
      brlaser # Brother laser printer driver
      foomatic-db-ppds-withNonfreeDb # Printer PPD files

      # Network & System Tools
      wget # File downloader
      tcpdump # Network analyzer
      openssl # Cryptography toolkit
      procps # Process utilities
      duf # Disk usage/free utility

      # Development Tools
      inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default # Claude Code CLI (latest)
      pkgs-unstable.opencode
      pkgs-unstable.opencode-desktop
      pkgs-unstable.opencode-claude-auth
      uv # Python package manager / MCP server runner
      xh
      posting
    ];
  };
}
