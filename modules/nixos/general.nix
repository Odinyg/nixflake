{
  lib,
  pkgs,
  config,
  ...
}:
{

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

    };
    nixpkgs.config.allowUnfree = true;
    services.openssh.enable = true;
    nixpkgs.config.permittedInsecurePackages = [
      "electron-19.1.9"
      "electron-25.9.0"
      "electron-29.4.6"
      "python3.12-youtube-dl-2021.12.17"
    ];
    nix = {
      package = pkgs.nixVersions.stable;
      extraOptions = lib.optionalString (
        config.nix.package == pkgs.nixVersions.stable
      ) "experimental-features = nix-command flakes
           warn-dirty = false";
    };
    environment.systemPackages = with pkgs; [
      openvpn
      noti # Create notifications programmatically
      nmap
      #### ZIP etc ####
      unzip
      unrar
      zip

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
      protonup-qt
      lutris
      (lutris.override {
        extraPkgs = pkgs: [
          pkgs.libnghttp2
          pkgs.winetricks
        ];
      })
      nixfmt-rfc-style
      nixd
      sshs
      ripgrep
      zoxide
      tldr
      just

      age
      sops
      fluxcd
      obsidian
      flatpak
      beszel
      docker
      polkit
      ansible
      libreoffice
      #     xdg-desktop-portal-hyprland
    ];
    services.flatpak.enable = true;
    programs.zsh.enable = true;
    programs.hyprland.enable = true;

    time.timeZone = "Europe/Oslo";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
