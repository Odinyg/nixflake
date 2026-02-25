{ config, lib, pkgs, ... }:

{
  options = {
    oterm = {
      enable = lib.mkEnableOption "oterm - Terminal UI for Ollama";
    };
  };

  config = lib.mkIf config.oterm.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        oterm
      ];
    };
  };
}
