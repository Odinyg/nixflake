{ config, lib, ... }: {

  options = {
    rofi = {
      enable = lib.mkEnableOption {
        description = "Enable polybar,sxhkd and rofi.";
        default = false;
      }; 
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.rofi.enable {
    services.polybar.enable = true;
    services.polybar.script = "polybar example"; 
    services.sxhkd.enable = true;

    xdg.configFile."sxhkd/sxhkdrc".source = ./dotfiles/sxhkdrc;
    xdg.configFile."polybar/config".source = ./dotfiles/config;
    xdg.configFile."rofi/nord.rasi".source = ./dotfiles/rofi-nord.rasi;
    xdg.configFile."rofi/rounded-common.rasi".source = ./dotfiles/rounded-common.rasi;
    xdg.configFile."bspwm/bspwmrc".source = ./dotfiles/bspwmrc;
    programs.rofi = {
      enable = true; 
      theme = "nord";
    };
  };
}
