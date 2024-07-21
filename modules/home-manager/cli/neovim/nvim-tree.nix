{
  programs.nixvim.plugins.nvim-tree = {
    enable = true;
    git = {
      enable = true;
      ignore = false;
    };
    renderer.indentWidth = 1;
    diagnostics.enable = true;
    updateFocusedFile.enable = true;
  };

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>lua require('nvim-tree.api').tree.toggle()<CR>";
      options.desc = "Toggle Tree";
      options.silent = true;
    }
  ];
}
