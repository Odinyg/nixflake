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
      ) "experimental-features = nix-command flakes";
    };
    packages = with pkgs; [
      firefox
      deluge
      protonup-qt
      lutris
      (lutris.override {
        extraPkgs = pkgs: [
          pkgs.libnghttp2
          pkgs.winetricks
        ];
      })
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

    time.timeZone = "Europe/Oslo";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
