{
  config,
  lib,
  pkgs,
  ...
}:
{

  options = {
    game = {
      enable = lib.mkEnableOption {
        description = "Enable game.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.game.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        lutris
      ];

    };
    programs.gamescope.enable = true;
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
}
