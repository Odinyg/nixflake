{ config, pkgs, ...}:
{
#   
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
      nvim-treesitter.withAllGrammars
      nvim-lspconfig
      harpoon
      nvim-fzf
      telescope-nvim
    ];
    extraPackages = with pkgs; [
      nixd
      lua
      terraform
      gopls
      nodePackages.bash-language-server
      
    ];
    
  };
}
