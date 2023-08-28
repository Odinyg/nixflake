{
  imports = [
 #    ./autocommands.nix
 #   ./completion.nix
 #   ./keymappings.nix
 #  ./options.nix
 #   ./plugins
 #   ./todo.nix
  ];

  home = {
    shellAliases.v = "nvim";

    sessionVariables.EDITOR = "nvim";
  };

  programs.neovim = {
    enable = true;
  };
}
