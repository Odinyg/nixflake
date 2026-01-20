{ config, lib, pkgs, ... }:

{
  options = {
    alpaca = {
      enable = lib.mkEnableOption {
        description = "Enable Alpaca - GTK4 Ollama client";
        default = false;
      };
    };
  };

  config = lib.mkIf config.alpaca.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        # alpaca  # Not available in stable
      ];
    };
  };
}
