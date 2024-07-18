{ config, lib, ... }: {
  options = {
    game = {
      enable = lib.mkEnableOption {
        description = "Enable gameing.";
        default = false;
      };
    };
  };

  config = lib.mkIf config.game.enable {
    programs.gamescope.enable = true;
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
};
};
}

