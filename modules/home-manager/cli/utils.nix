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
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    home.packages = with pkgs; [

      open-webui
      xcape

      feh
      xarchiver
      cloudflared
      drawio
      freecad
      vlc
      proton-pass
      curaengine_stable
      autokey
      wine
      ######## kubernetes
      k9s
      kubectx
      fluxcd
      kubernetes-helm
      openssl

      code-cursor
      ventoy-full

      ###### tdrop dependencys ######
      xorg.xwininfo

      planify

      procps
      xorg.xprop
      xorg.xwininfo
      remmina
      filezilla
      rpi-imager
      wget
      kubernetes
      minikube
      xfce.thunar

    ];
  };
}
