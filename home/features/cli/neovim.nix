{ config, pkgs, ...}:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      mason-lspconfig-nvim
      mason-nvim
      nvim-treesitter.withAllGrammars
      harpoon
      nvim-fzf
      lazy-nvim
    ];

  };
}
