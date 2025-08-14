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
    ];
  };
}
