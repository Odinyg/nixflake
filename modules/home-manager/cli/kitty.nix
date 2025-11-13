{ config, lib, ... }:
{

  options = {
    kitty = {
      enable = lib.mkEnableOption "Kitty terminal emulator";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.kitty.enable {
    programs.kitty = {
      enable = true;
      extraConfig = "confirm_os_window_close 0";
      shellIntegration.enableZshIntegration = true;
    };
  };
}
