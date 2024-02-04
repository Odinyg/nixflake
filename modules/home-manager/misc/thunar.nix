{config, lib,pkgs,... }: {

  options = {
    thunar = {
      enable = lib.mkEnableOption {
        description = "Enable several thunar";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user}= lib.mkIf config.thunar.enable {

    home.packages = with pkgs; [
    xfce.exo 
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler 
    gvfs
  ];
  };
}