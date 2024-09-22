{
  config,
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
      ./flash.nix
      ./lint.nix
      ./obsidian.nix
    ];

    home = {
      shellAliases.v = "nvim";

      sessionVariables.EDITOR = "nvim";
    };
  };

}
