{ pkgs, lib, ... }: {
   programs.zsh = {
    oh-my-zsh = {
      enable = true;
      plugins = [
          "fzf"
      ];
    };
  };
}
