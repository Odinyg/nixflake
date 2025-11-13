{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    _1password = {
      enable = lib.mkEnableOption "_1password";
    };
  };
  config = lib.mkIf config._1password.enable {
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "odin" ];

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
