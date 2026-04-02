{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  # options.environment only exists in NixOS, not standalone Home Manager
  standalone = !(options ? environment);

  hmConfig = {
    xdg.configFile."xfce4/helpers.rc".text = ''
      [Default]
      TerminalEmulator=kitty
    '';
  };
in
{

  options = {
    thunar = {
      enable = lib.mkEnableOption "Thunar file manager";
    };
  };
  config = lib.mkMerge (
    [
      {
        home-manager.users.${config.user} = lib.mkIf config.thunar.enable hmConfig;
      }
    ]
    ++ lib.optionals (!standalone) [
      (lib.mkIf config.thunar.enable {
        environment.systemPackages = with pkgs; [
          xfce.exo
          xfce.thunar
          xfce.thunar-archive-plugin
          xfce.tumbler
          xfce.xfconf
          gvfs
        ];
      })
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.thunar.enable hmConfig)
    ]
  );
}
