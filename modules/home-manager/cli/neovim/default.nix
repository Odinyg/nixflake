{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    neovim = {
      enable = lib.mkEnableOption {
        description = "Enable Neovim";
        default = false;
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.neovim.enable {
    imports = [
      ./nixvim.nix
      ./lsp.nix
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
  };

}
