{ config, lib, ... }: {

  options = {
    bspwm = {
      enable = lib.mkEnableOption {
        description = "Enable bspwm.";
        default = false;
      }; 
    };
  };

    config = lib.mkIf  config.bspwm.enable{
    services = {
      picom.enable = true;
      xserver = {
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
        xkb.layout = "us";
        xkb.variant = "";
      };
    };
  };
}
  
    
