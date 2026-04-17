{
  lib,
  config,
  ...
}:
let
  cfg = config.localsend;
in
{
  options.localsend.enable = lib.mkEnableOption "localsend file sharing";

  config = lib.mkIf cfg.enable {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
