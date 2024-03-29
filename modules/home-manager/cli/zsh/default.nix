{ config, pkgs, lib, ... }: {

  options = {
    zsh = {
      enable = lib.mkEnableOption {
        description = "Enable zsh";
        default = false;
      }; 
    };
  };



  config.home-manager.users.${config.user} = lib.mkIf config.zsh.enable {


  imports = [
    ./zsh.nix
    #./exa.nix
  ];

  home = {
    shellAliases = import ./aliases.nix;
  };

  programs = {
    zsh.enable = true;
    autojump.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf.enable = true;
  };
  };
}
