{
  imports = [
 #    ./autocommands.nix
 #   ./completion.nix
 #   ./keymappings.nix
 #  ./options.nix
 #   ./plugins
 #   ./todo.nix
     ./nixvim.nix
  ];

  home = {
    shellAliases.v = "nvim";

    sessionVariables.EDITOR = "nvim";
  };

}
