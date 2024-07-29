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
      autokey
      xarchiver
      xclip
      pyprland
      tgpt
      vlc
      proton-pass
      anbox
      pgadmin4-desktopmode
      nixfmt-rfc-style
      autokey

      zoxide
      planify
      tldr
      just
      xdotool      
      procps
      tdrop
      planify
      xorg.xprop
      xorg.xwininfo
      zellij
      teamviewer
      ytui-music
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
