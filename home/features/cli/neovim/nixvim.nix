{ config, pkgs, nixvim, ...}:
{
   
  programs.nixvim = {
    enable = true;
    colorschemes.nord.enable = true;
    clipboard.register = "unnamedplus";
    options = { 
      number = true;
      relativenumber = true;
      shiftwidth = 2;
    };
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = {
      telescope.enable = true;
      treesitter.enable = true;
      lsp = {
        enable = true;
	servers = {
	pylsp.enable = true;
	rnix-lsp.enable = true;
	gopls.enable = true;
	bashls.enable = true;
	cmake.enable = true;
	lua-ls.enable = true;
	nixd.enable = true;
	terraformls.enable = true;
	csharp-ls.enable = true;
	eslint.enable = true;
	html.enable = true;
	yamlls.enable = true;

	};
      };
      harpoon.enable = true;
    };
  };
}
