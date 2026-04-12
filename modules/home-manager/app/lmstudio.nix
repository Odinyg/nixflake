{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.lmstudio;
in
{
  options = {
    lmstudio = {
      enable = lib.mkEnableOption "LM Studio";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.packages = [ pkgs.lmstudio ];
  };
}
