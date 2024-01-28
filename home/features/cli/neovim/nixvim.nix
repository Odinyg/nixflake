{ ...}:
{
   
  programs.nixvim = {
    globals.mapleader = " ";
    enable = true;
    colorschemes.nord.enable = true;
    clipboard.register = "unnamedplus";
    options = { 
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      smartcase = true;
      smartindent = true;
      expandtab = true;
      tabstop = 4;
      scrolloff = 8;
      };
    viAlias = true;
    vimAlias = true;   

    plugins = {
      comment-nvim.enable = true;
      nix.enable = true;
      mini.enable = true;
      which-key.enable = true;
      lualine = {
        enable = true;
      };
      indent-blankline = {
        enable = true;
        whitespace.removeBlanklineTrail = true;
  };
      toggleterm = {
        enable = true;
        openMapping = "<c-t>";
	direction = "float";
	floatOpts = { border = "single"; };
      };
      telescope = {
      enable = true;
      };
      treesitter = {
      enable = true;
      nixGrammars = true;
      nixvimInjections = true;
      };
      harpoon.enable = true;

      };
    };
}
