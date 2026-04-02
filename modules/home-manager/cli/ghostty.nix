{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.ghostty;
  standalone = !(options ? nixpkgs);
  hmConfig = {
    home.sessionVariables.TERMINAL = lib.mkForce "ghostty";
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        term = "xterm-256color";
        confirm-close-surface = false;
      };
    };
  };
in
{
  options = {
    ghostty = {
      enable = lib.mkEnableOption "Ghostty terminal emulator";
    };
  };

  config = lib.mkMerge (
    [
      {
        home-manager.users.${config.user} = lib.mkIf cfg.enable hmConfig;
      }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf cfg.enable hmConfig)
    ]
  );
}
