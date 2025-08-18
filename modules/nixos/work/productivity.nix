{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    work.productivity = {
      enable = lib.mkEnableOption {
        description = "Enable productivity tools (Insync, Flameshot, Kuro)";
        default = false;
      };
    };
  };

  config = lib.mkIf config.work.productivity.enable {
    environment.systemPackages = with pkgs; [
      insync
      flameshot
      kuro
    ];
  };
}