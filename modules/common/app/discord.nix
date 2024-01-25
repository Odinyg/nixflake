{ config, pkgs, lib, ... }: {
  options = {
    discord = {
      enable = lib.mkEnableOption {
        description = "Enable Discord.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.discord.enable {
    unfreePackages = [ "discord" ];
    home-manager.users.none = {
      home.packages = with pkgs; [ discord ];
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
