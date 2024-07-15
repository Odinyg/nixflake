{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    termUtils = {
      enable = lib.mkEnableOption {
        description = "Enable several TerminalExtra";
        default = false;
      };
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.termUtils.enable {
    home.packages = with pkgs; [

      #### ProgramStuff ####
      python3
      python312Packages.pip
      go
      docker
      docker-compose
      vagrant
      ansible
      nushell

      openvpn
      noti # Create notifications programmatically
      dos2unix # Convert Windows text files
      nmap

      #### ZIP etc ####
      unzip
      unrar
      zip

      #### Terminal Improvments ####
      lf
      fd
      bat
      ripgrep
      magic-wormhole

      #### Terminal essentials####
      gnupg # Encryption
      expect
      consul
      st
      stdenv
      plocate
      killall
      inetutils # Includes telnet
      fzf




      pandoc # Convert text documents
      usermount
      xfce.thunar
      htop
      ctop
      #      xorg.libX11
      #      xorg.libX11.dev
      #      xorg.libxcb
      #      xorg.libXft
      #      xorg.libXinerama
      #      xorg.xinit
      #      xorg.xinput

    ];
  };
}
