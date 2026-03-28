{ lib, pkgs, pkgs-unstable, config, ... }: {

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
    nix = {
      package = pkgs.nixVersions.stable;
    };
    environment.systemPackages = with pkgs; [
      noti # Create notifications programmatically
      nmap
      #### ZIP etc ####
      unzip
      unrar
      zip
      #### Terminal Improvments ####
      lf
      #### Terminal essentials####
      gnupg # Encryption
      expect
      st
      killall
      inetutils # Includes telnet
      pandoc # Convert text documents
      usermount
      ctop
      nvtopPackages.full
      firefox
      deluge
      nixd
      sshs
      tldr
      just
      age
      sops
      ssh-to-age
      pkgs-unstable.obsidian
      ansible
      colmena
      devenv
      ventoy-full
    ];
    nixpkgs.config.permittedInsecurePackages = [
      "ventoy-1.1.05"
    ];
    services.gnome.gnome-online-accounts.enable = true;
    services.flatpak.enable = true;
    programs.appimage.enable = true;
    programs.zsh = {
      enable = true;
      };


    # Keyd: CapsLock → Escape on tap, Ctrl on hold
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main = {
          capslock = "overload(control, esc)";
        };
      };
    };

    systemd.services.NetworkManager-wait-online.enable = false;

    time.timeZone = "Europe/Oslo";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
