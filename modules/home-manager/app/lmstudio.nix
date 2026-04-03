{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    lmstudio = {
      enable = lib.mkEnableOption "LM Studio";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.lmstudio.enable {
    home.packages = [ pkgs.lmstudio ];
  };
}
