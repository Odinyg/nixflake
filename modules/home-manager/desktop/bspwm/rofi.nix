{ config, lib, ... }:
{

  options = {
    rofi = {
      enable = lib.mkEnableOption {
        description = "Enable polybar,sxhkd and rofi.";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.rofi.enable {
    services.polybar= {
      enable = true;
      script = "~/.config/polybar/launch.sh";
    };
    services.sxhkd.enable = true;

    xdg.configFile."sxhkd/sxhkdrc" = {
      source = ./dotfiles/sxhkdrc;
      executable = true;
    };
    xdg.configFile."polybar/config".source = ./dotfiles/config;
    xdg.configFile."rofi/nord.rasi".source = ./dotfiles/rofi-nord.rasi;
    xdg.configFile."rofi/rounded-common.rasi".source = ./dotfiles/rounded-common.rasi;
    xdg.configFile."bspwm/bspwmrc" = {
      source = ./dotfiles/bspwmrc;
      executable = true;
    };
    xdg.configFile."bspwm/monitor.sh" = {
      source = ./dotfiles/monitor.sh;
      executable = true;
    };
    xdg.configFile."polybar/launch.sh" = {
      source = ./dotfiles/polybar-launch.sh;
      executable = true;
    };

    programs.rofi = {
      enable = true;
    };
  };
}
