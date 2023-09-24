{
  imports = [
     ./nixvim.nix
     ./harpoon.nix
     ./telescope.nix
     ./nvim-tree.nix
  ];

  home = {
    shellAliases.v = "nvim";

    sessionVariables.EDITOR = "nvim";
  };

}
