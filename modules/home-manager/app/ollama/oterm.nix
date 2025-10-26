{ config, lib, pkgs, ... }:

{
  options = {
    oterm = {
      enable = lib.mkEnableOption {
        description = "Enable oterm - Terminal UI for Ollama";
        default = false;
      };
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
