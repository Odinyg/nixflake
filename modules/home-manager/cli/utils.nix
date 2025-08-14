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
      protonmail-desktop
      yazi
      protonvpn-gui

      brlaser
      foomatic-db-ppds-withNonfreeDb
      atac
      kdePackages.kolourpaint
      burpsuite
      postman
      brave
      github-desktop
      pinta
      waveterm
      keeweb
      warp-terminal
      burpsuite
      warp
      satty
      xcape
      feh
      xarchiver
      vlc
      warp-terminal
      proton-pass
      curaengine_stable
      autokey
      #orca-slicer
      wine
      ######## kubernetes
      k9s
      kubectx
      fluxcd
      kubernetes-helm
      kubernetes
      openssl
      code-cursor

      tcpdump
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
      xfce.thunar
      kuro

    ];
  };
}
