{
  config,
  lib,
  options,
  ...
}:
let
  standalone = !(options ? nixpkgs);
  hmConfig = {
    home.sessionVariables.TERMINAL = "kitty";
    programs.kitty = {
      enable = true;
      extraConfig = "confirm_os_window_close 0";
      shellIntegration.enableZshIntegration = true;
    };
  };
in
{
  options = {
    kitty = {
      enable = lib.mkEnableOption "Kitty terminal emulator";
    };
  };

  config = lib.mkMerge (
    [
      {
        home-manager.users.${config.user} = lib.mkIf config.kitty.enable hmConfig;
      }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.kitty.enable hmConfig)
    ]
  );
}
