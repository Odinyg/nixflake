{ config, lib, ... }: {

  options = {
    neovim = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Neovim";
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
      ./lint.nix
      ./mini.nix
      ./conform.nix
      ./obsidian.nix
      ./auto-save.nix
      ./render-markdown.nix
    ];

    home = {
      shellAliases.v = "nvim";

      sessionVariables.EDITOR = "nvim";

      file.".config/nixvim/scripts/scratchpad.sh" = {
        source = ./scripts/scratchpad.sh;
        executable = true;
      };
    };
  };

}
