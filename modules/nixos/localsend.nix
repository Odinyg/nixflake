{ lib, config, ... }:
let
  cfg = config.localsend;
in
{
  options.localsend = {
    enable = lib.mkEnableOption "LocalSend, a cross-platform AirDrop alternative";
  };

  config = lib.mkIf cfg.enable {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
