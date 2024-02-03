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

    xdg.configFile."sxhkd/sxhkdrc".source = ./sxhkdrc;
    xdg.configFile."polybar/config".source = ./config;
    programs.rofi = {
      enable = true; 
      theme = "Nord";
    };
  };
}
