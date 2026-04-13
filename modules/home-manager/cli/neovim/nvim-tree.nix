{
  programs.nixvim = {
    plugins.nvim-tree = {
      enable = true;
      settings = {
        git = {
          enable = true;
          ignore = false;
        };
        renderer.indent_width = 1;
        diagnostics.enable = true;
        update_focused_file.enable = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>lua require('nvim-tree.api').tree.toggle()<CR>";
        options.desc = "Toggle Tree";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<cmd>lua require('nvim-tree.api').tree.focus()<CR>";
        options.desc = "Focus Tree";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<cmd>wincmd l<CR>";
        options.desc = "Focus Editor";
        options.silent = true;
      }
    ];
  };
}
