{
      programs.nixvim.plugins.cmp-nvim-lsp.enable = true;
      programs.nixvim.plugins.cmp-buffer.enable = true;
      programs.nixvim.plugins.cmp= {

        enable = true;
        settings.sources =
        [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
          { name = "luasnip"; }
          { name = "cmdline"; }
        ];
        settings = {
          mapping = {
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" ="cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          };
        };
    };
}
