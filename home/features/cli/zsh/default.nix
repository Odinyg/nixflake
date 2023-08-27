{
  imports = [
    ./zsh.nix
    ./exa.nix
  ];

  home = {
    shellAliases = import ./aliases.nix;
  };

  programs = {
    autojump.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf.enable = true;
  };
}
