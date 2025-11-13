{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    discord = {
      enable = lib.mkEnableOption "Discord (Vesktop)";
    };
  };

  config = lib.mkIf config.discord.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        vesktop
      ];
      xdg.configFile."discord/settings.json".text = ''
        {
          "BACKGROUND_COLOR": "#162e52",
          "IS_MAXIMIZED": false,
          "IS_MINIMIZED": false,
          "OPEN_ON_STARTUP": false,
          "MINIMIZE_TO_TRAY": false,
          "SKIP_HOST_UPDATE": true
        }
      '';
    };
  };
}
