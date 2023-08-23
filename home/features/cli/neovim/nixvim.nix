{ config, pkgs, ...}:
{
   
  programs.nixvim= {
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
    plugins {
      telescope.enable = true
      treesitter.enable = true
      lsp {
        enable = true
	lsp.enableServers [
	pylsp
	rnix-lsp
	gopls
	bashls
	cmake
	lua-ls
	nixd
	terraformls
	csharp-ls
	eslint
	html
	yamlls

	];
      };
    harpoon.enable = true
    };
  };
}
