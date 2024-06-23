{
      programs.nixvim.plugins.cmp-nvim-lsp.enable = true;
      programs.nixvim.plugins.cmp-buffer.enable = true;
      programs.nixvim.plugins.cmp= {

        enable = true;
        settings = {
          completion.keyword_length = 2;
          sources = [
              { name = "nvim_lsp"; keyword_length = 3;}
              { name = "path"; keyword_length = 3; }
              { name = "buffer"; keyword_length = 3;}
              { name = "luasnip"; keyword_length = 3;}
    #          { name = "cmdline"; keyword_length = 3;}
          ];
          mapping = {
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = false })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" ="cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          };
        };
      };
}
