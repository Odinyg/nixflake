{ config, pkgs, lib, ... }: {

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
      xfce.thunar # GUI file manager

      # Image Viewers & Screenshot
      feh # Lightweight image viewer
      satty # Screenshot annotation

      # Archive Management
      xarchiver # Archive manager

      # Remote Access
      remmina # Remote desktop client
      filezilla # FTP/SFTP client

      # System Utilities
      wine # Windows compatibility layer
      autokey # Automation tool
      xcape # Key modifier tool
      rpi-imager # Raspberry Pi imager (temporarily disabled due to build error)

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
      claude-code # Claude Code CLI
      uv # Python package manager / MCP server runner
      xh
      posting
    ];
  };
}
