{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    utils = {
      enable = lib.mkEnableOption {
        description = "Enable several utils";
        default = false;
      };
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.utils.enable {
    home.packages = with pkgs; [
      feh
      xarchiver
     # nomachine-client
      pyprland
      tgpt
      vlc
      protonmail-desktop
      anbox
      pgadmin4-desktopmode
      nixfmt-rfc-style
      autokey
      planify
      tldr
      just
      teamviewer
      ytui-music
      youtube-music
      remmina
      filezilla
      thunderbird
      rpi-imager
      wget
      kubernetes
      minikube

      #### virt-manager ####
      #     qemu
      #      virt-manager
      xfce.thunar

    ];
  };
}
