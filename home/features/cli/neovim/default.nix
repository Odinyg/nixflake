{
  imports = [
     ./nixvim.nix
     ./harpoon.nix
     ./telescope.nix
     ./nvim-tree.nix
     ./cmp.nix
     ./maps.nix
  ];

  home = {
    shellAliases.v = "nvim";

    sessionVariables.EDITOR = "nvim";
  };

}
