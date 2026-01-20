{ lib, pkgs, config, ... }: {

  options = {
    general = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable general system configuration";
      };
    };
  };
  config = lib.mkIf config.general.enable {
    xdg.mime.defaultApplications = {
      # Word documents
      "application/msword" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop";

      # Excel spreadsheets
      "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop";

      # PowerPoint presentations
      "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop";
    };
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
      htop
      ctop
      nvtopPackages.full
      firefox
      deluge
      ripgrep
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
      devenv
    ];
    services.flatpak.enable = true;
    programs.appimage.enable = true;
    programs.zsh.enable = true;

    systemd.services.NetworkManager-wait-online.enable = false;

    time.timeZone = "Europe/Oslo";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
