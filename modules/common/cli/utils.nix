{ config, pkgs, lib, ... }: {

  options = {
    utils = {
      enable = lib.mkEnableOption {
        description = "Enable several utils";
        default = false;
      }; 
    };
  };



  config.home-manager.users.none = lib.mkIf config.utils.enable {

    home.packages = with pkgs; [
      dos2unix # Convert Windows text files
      inetutils # Includes telnet
      youtube-dl # Convert web videos
      pandoc # Convert text documents
      mpd # TUI slideshows
      mpv # Video player
      gnupg # Encryption
      awscli2
      awslogs
      ansible
      expect
      consul
      noti # Create notifications programmatically
      xclip
      unzip
      qemu
      st
      stdenv
      plocate
      ripgrep
      killall
      fzf
      xfce.thunar
      burpsuite
      virt-manager
      bat
      lf
      htop
      ctop
      fd

    ];
    };
  } 
