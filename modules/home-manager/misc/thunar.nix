{
  config,
  lib,
  pkgs,
  ...
}:
{

  options = {
    thunar = {
      enable = lib.mkEnableOption {
        description = "Enable several thunar";
        default = false;
      };
    };
  };
  config = lib.mkIf config.thunar.enable {

    environment.systemPackages = with pkgs; [
      xfce.exo
      xfce.thunar
      xfce.thunar-archive-plugin
      xfce.tumbler
      gvfs
    ];
  };
}
