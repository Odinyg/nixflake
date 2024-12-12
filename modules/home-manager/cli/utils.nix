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
      feh
      autokey
      xarchiver
      hugo
      ksnip
      xclip
      cloudflared
      bat
      pyprland
      tgpt
      vlc
      proton-pass
      anbox
      curaengine_stable
      nixfmt-rfc-style
      autokey
      sshs
      ripgrep
      arandr
      wine
      ######## kubernetes
      k9s
      kubectx
      fluxcd

      code-cursor

      ###### tdrop dependencys ######
      xorg.xwininfo
      xdotool

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
