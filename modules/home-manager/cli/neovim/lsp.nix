{
      programs.nixvim.plugins.lsp = {
        enable = true;
	servers = {
	gopls.enable = true;
	bashls.enable = true;
	cmake.enable = true;
	lua-ls.enable = true;
	nil_ls = {
	  enable = true;
	  autostart = true;
	};
	terraformls.enable = true;
	csharp-ls.enable = true;
	eslint.enable = true;
	html.enable = true;
	yamlls.enable = true;
	pyright.enable = true;
    
        };
      };
      programs.nixvim.plugins.packer.enable = true;
}
