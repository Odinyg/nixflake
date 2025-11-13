{
  lib,
  config,
  pkgs,
  ...
}:
{

  options = {
    _1password = {
      enable = lib.mkEnableOption "locate";
    };
  };
  config = lib.mkIf config.locate.enable {
    services.locate.enable = true;
    services.locate.locate = pkgs.mlocate;
  };
}
