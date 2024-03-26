{ config, pkgs, lib, ... }: {

  options = {
    utils = {
      enable = lib.mkEnableOption {
        description = "Enable several utils";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user}= lib.mkIf config.utils.enable {
    home.packages = with pkgs; [
      autorandr
      openvpn
      vagrant
      magic-wormhole
      nmap
      vlc
      todoist
      planify
      ripgrep
      dos2unix # Convert Windows text files
      inetutils # Includes telnet
      youtube-dl # Convert web videos
      pandoc # Convert text documents
      mpd # TUI slideshows
      mpv # Video player
      gnupg # Encryption
      ansible
      expect
      consul
      noti # Create notifications programmatically
      xclip
      unzip
      qemu
      st
      stdenv
      xclip
      plocate
      ripgrep
      killall
      usermount
      gnugrep
      openssl
      fzf
      xfce.thunar
      burpsuite
      virt-manager
      bat
      lf
      htop
      ctop
      fd
      nmap
      plocate
      xorg.libX11
      xorg.libX11.dev
      xorg.libxcb
      xorg.libXft
      xorg.libXinerama
      xorg.xinit
      xorg.xinput

    ];
    };
  } 
