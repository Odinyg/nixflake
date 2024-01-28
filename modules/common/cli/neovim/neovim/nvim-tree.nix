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
      key = "<leader>n";
     # desc = "Toggle Tree";
      action = "<cmd>lua require('nvim-tree.api').tree.toggle()<CR>";
      }
  ];
}
