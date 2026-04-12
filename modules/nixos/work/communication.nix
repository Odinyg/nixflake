{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.work.communication;
in
{
  options = {
    work.communication = {
      enable = lib.mkEnableOption "work communication tools (Zoom, AnyDesk)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      anydesk
      teams-for-linux
      zoom-us
    ];
  };
}
