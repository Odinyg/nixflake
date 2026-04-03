{ config, lib, ... }:
let
  cfg = config.ghostty;
in
{

  options = {
    ghostty = {
      enable = lib.mkEnableOption "Ghostty terminal emulator";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.sessionVariables.TERMINAL = "ghostty";
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        term = "xterm-256color";
        confirm-close-surface = false;
      };
    };
  };
}
