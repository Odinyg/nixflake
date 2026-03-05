{ config, pkgs, pkgs-unstable, inputs, lib, ... }: {

  options = {
    utilities = {
      enable = lib.mkEnableOption "miscellaneous utility applications";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.utilities.enable {
    # Smart directory navigation
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
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
      rustdesk # Open-source remote desktop
      teamviewer # Remote desktop and support
      moonlight-qt # Low-latency streaming client (pairs with Sunshine)
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
      inputs.claude-code.packages.${pkgs.system}.default # Claude Code CLI (latest)
      pkgs-unstable.opencode
      uv # Python package manager / MCP server runner
      xh
      posting
    ];
  };
}
