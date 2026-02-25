{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    zsh = {
      enable = lib.mkEnableOption "Zsh shell";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.zsh.enable {

    imports = [
      ./zsh.nix
      ./eza.nix
    ];
    home = {
      shellAliases = import ./aliases.nix;
    };

    programs = {
      zsh.enable = true;
      autojump.enable = true;
      fzf.enable = true;
      carapace = {
        enable = true;
        enableZshIntegration = true;
      };
    };
  };
}
