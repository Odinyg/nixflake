{ lib, pkgs, config, ... }: {

  options = {
    general = {
      enable = lib.mkEnableOption {
        description = "Enable several general";
        default = true;
      };
    };
  };
  config = lib.mkIf config.general.enable {
    xdg.mime.defaultApplications = {
      "application/msword" = "libreoffice-writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
        "libreoffice-writer.desktop";

    };
    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.nixVersions.stable;
      extraOptions =
        lib.optionalString (config.nix.package == pkgs.nixVersions.stable) ''
          experimental-features = nix-command flakes
                     warn-dirty = false'';
    };
    environment.systemPackages = with pkgs; [
      openvpn
      noti # Create notifications programmatically
      nmap
      #### ZIP etc ####
      unzip
      unrar
      zip
      kitty
      #### Terminal Improvments ####
      lf
      fd
      bat
      #### Terminal essentials####
      gnupg # Encryption
      expect
      consul
      st
      stdenv
      killall
      inetutils # Includes telnet
      fzf
      pandoc # Convert text documents
      usermount
      xfce.thunar
      htop
      ctop
      #nvtopPackages.full
      firefox
      deluge
      ripgrep
      nixfmt-rfc-style
      nixd
      sshs
      zoxide
      tldr
      just
      age
      sops
      ssh-to-age
      fluxcd
      obsidian
      flatpak
      docker
      polkit
      ansible
      #libreoffice
      #     xdg-desktop-portal-hyprland
    ];
    services.flatpak.enable = true;
    programs.appimage.enable = true;
    programs.zsh.enable = true;

    systemd.services.NetworkManager-wait-online.enable = false;

    time.timeZone = "Europe/Oslo";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
