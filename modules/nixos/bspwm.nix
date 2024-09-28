{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    bspwm = {
      enable = lib.mkEnableOption {
        description = "Enable Crypt";
        default = false;
      };
    };
  };
  config = lib.mkIf config.bspwm.enable {

  fonts.enable = true;
  rofi.enable = true;
  randr.enable = true;
  services.displayManager = {
      defaultSession = "none+bspwm";
      autoLogin.enable = true;
      autoLogin.user = "none";
  };
  services.xserver = {
    enable = true;
    windowManager.bspwm.enable = true;
    displayManager = {
      lightdm = { 
        enable = true; 
      }; 
    };

#### Keyboard Layout ###
    xkb.layout = "us";
    xkb.variant = "";
  };
    environment.systemPackages = with pkgs; [
      sxhkd
      bspwm
      rofi
      polybar
      xorg.libX11
      xorg.libX11.dev
      xorg.libxcb
      xorg.libXft
      xorg.libXinerama
      xorg.xinit
      feh
      pavucontrol
    ];
  };
}
