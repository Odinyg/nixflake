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
      xfce.exo
      xfce.thunar
      xfce.thunar-archive-plugin
      xfce.tumbler
      xfce.xfconf
      gvfs
    ];

    home-manager.users.${config.user} = {
      xdg.configFile."xfce4/helpers.rc".text = ''
        [Default]
        TerminalEmulator=kitty
      '';
    };
  };
}
