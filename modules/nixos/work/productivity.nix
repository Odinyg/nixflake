{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    work.productivity = {
      enable = lib.mkEnableOption "productivity tools (Insync, Flameshot, Kuro, OnlyOffice)";
    };
  };

  config = lib.mkIf config.work.productivity.enable {
    environment.systemPackages = with pkgs; [
      insync
      flameshot
      kuro
      onlyoffice-desktopeditors
    ];
  };
}