{
  config,
  lib,
  pkgs,
  ...
}:
{

  options = {
    thunar = {
      enable = lib.mkEnableOption "Thunar file manager";
    };
  };
  config = lib.mkIf config.thunar.enable {

    environment.systemPackages = with pkgs; [
      xfce4-exo
      thunar
      thunar-archive-plugin
      tumbler
      xfconf
      gvfs
    ];
  };
}
