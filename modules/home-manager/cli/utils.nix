{ config, pkgs, lib, ... }: {

  options = {
    utils = {
      enable = lib.mkEnableOption {
        description = "Enable several utils";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user}= lib.mkIf config.utils.enable {
    home.packages = with pkgs; [
      gnome.gnome-calculator
      feh
      xarchiver
      nomachine-client
      vlc
      planify
   

      #### virt-manager ####
      qemu
      virt-manager
      xfce.thunar

    ];
    };
  } 
