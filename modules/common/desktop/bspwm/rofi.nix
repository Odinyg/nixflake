{ config, lib, ... }: {

  options = {
    rofi = {
      enable = lib.mkEnableOption {
        description = "Enable bspwm.";
        default = false;
      }; 
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.rofi.enable {
    programs.rofi = {
      enable = true; 
      theme = "rounded-nord-dark";
    };
  };
}
