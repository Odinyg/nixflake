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
      };
    viAlias = true;
    vimAlias = true;
    plugins = {
      comment-nvim.enable = true;
      toggleterm = {
        enable = true;
        openMapping = "<c-t>";
	direction = "float";
	floatOpts = { border = "single"; };
      };
    #   cmp-nvim-lsp.enable = true;
    #   nvim-cmp = {
    #     enable = true;
    #     sources = [
    #       {name = "path";}
    #       {name = "nvim_lsp";}
    #       {name = "luasnip";}
    #       {name = "crates";}
    #       {name = "buffer";}
    #     ];
    #     mapping = {
    #       "<C-d>" = "cmp.mapping.scroll_docs(-4)";
    #       "<C-f>" = "cmp.mapping.scroll_docs(4)";
    #       "<C-Space>" = "cmp.mapping.complete()";
    #       "<C-e>" = "cmp.mapping.abort()";
    #       "<CR>" = "cmp.mapping.confirm({ select = true })";
    #       "<Tab>" = {
    #         action = "cmp.mapping.select_next_item()";
    #         modes = ["i" "s"];
    #       };
    #       "<S-Tab>" = {
    #         action = "cmp.mapping.select_prev_item()";
    #         modes = ["i" "s"];
    #       };
    #     };
    #     snippet.expand = "luasnip";
    # };
      telescope = {
      enable = true;
      };
      treesitter = {
      enable = true;
      nixGrammars = true;
      nixvimInjections = true;

      };
      lsp = {
        enable = true;
	servers = {
	pylsp.enable = true;
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
        
	};
      };
      harpoon.enable = true;

      };
    };
}
