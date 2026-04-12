{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.work.development;
in
{
  options = {
    work.development = {
      enable = lib.mkEnableOption "development tools (GCC, Make, DBeaver, etc.)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dbeaver-bin
      rpiboot
    ];
  };
}
