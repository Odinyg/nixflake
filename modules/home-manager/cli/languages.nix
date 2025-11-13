{ config, pkgs, lib, ... }: {

  options = {
    languages = {
      enable = lib.mkEnableOption "programming language runtimes";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.languages.enable {
    home.packages = with pkgs; [
      # Programming Languages
      python3            # Python runtime
      go                 # Go programming language

      # Could add more languages here:
      # nodejs
      # rustc
      # gcc
      # etc.
    ];
  };
}
