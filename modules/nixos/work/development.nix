{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    work.development = {
      enable = lib.mkEnableOption "development tools (GCC, Make, DBeaver, etc.)";
    };
  };

  config = lib.mkIf config.work.development.enable {
    environment.systemPackages = with pkgs; [
      gcc
      gnumake
      dbeaver-bin
      expect
      rpiboot
      inetutils
    ];
  };
}