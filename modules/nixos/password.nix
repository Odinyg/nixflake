{
  lib,
  config,
  pkgs-unstable,
  ...
}:
{
  options = {
    _1password = {
      enable = lib.mkEnableOption "_1password";
    };
  };
  config = lib.mkIf config._1password.enable {
    programs._1password = {
      enable = true;
      package = pkgs-unstable._1password-cli;
    };
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ config.user ];
      package = pkgs-unstable._1password-gui;
    };
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "1password-gui-beta"
        "1password-gui"
        "1password"
      ];
  };
}
