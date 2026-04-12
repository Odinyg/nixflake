{ config, lib, ... }:
let
  cfg = config.kitty;
in
{
  options = {
    kitty = {
      enable = lib.mkEnableOption "Kitty terminal emulator";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.sessionVariables.TERMINAL = lib.mkDefault "kitty";
    programs.kitty = {
      enable = true;
      extraConfig = "confirm_os_window_close 0";
      shellIntegration.enableZshIntegration = true;
    };
  };
}
