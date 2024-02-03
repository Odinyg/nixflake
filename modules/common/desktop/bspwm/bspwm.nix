{ config, lib, ... }: {

  options = {
    bspwm = {
      enable = lib.mkEnableOption {
        description = "Enable bspwm.";
        default = false;
      }; 
    };
  };

  config.home-manager.users.none = lib.mkIf config.bspwm.enable {

  services.picom.enable = true;
  services.xserver = {
    enable = true;
    windowManager.bspwm.enable = true;
    displayManager = {
      defaultSession = "none+bspwm";
      autoLogin.enable = true;
      autoLogin.user = "none";
      lightdm = { 
        enable = true; 
        greeter.enable = true; 
      }; 
    };
    layout = "us";
    xkbVariant = "";
  };
    
