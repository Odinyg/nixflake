{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.bspwm.enable {
    home-manager.users.${config.user} = {
      xdg.configFile = {
        "rofi/nord.rasi".source = ./dotfiles/rofi-nord.rasi;
        "rofi/rounded-common.rasi".source = ./dotfiles/rounded-common.rasi;
        "sxhkd/sxhkdrc" = {
          source = ./dotfiles/sxhkdrc;
          executable = true;
        };
        "polybar/config".source = ./dotfiles/config;
        "polybar/launch.sh" = {
          source = ./dotfiles/polybar-launch.sh;
          executable = true;
        };
        "bspwm/bspwmrc" = {
          source = ./dotfiles/bspwmrc;
          executable = true;
        };
        "bspwm/monitor.sh" = {
          source = ./dotfiles/monitor.sh;
          executable = true;
        };
      };
    };
  };
}
