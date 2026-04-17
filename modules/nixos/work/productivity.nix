{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.work.productivity;
in
{
  options = {
    work.productivity = {
      enable = lib.mkEnableOption "productivity tools (Insync, Flameshot, Kuro, OnlyOffice)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      onlyoffice-desktopeditors
    ];
  };
}
