{
  programs.nixvim.plugins.telescope = {
    enable = true;
    settings.defaults = {
      file_ignore_patterns = [
        "^.git/"
        "^output/"
        "^target/"
      ];
    };
  };
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>ff";
      options.desc = "Find Files";
      action = "<cmd>lua require('telescope.builtin').find_files({hidden = true})<CR>";
    }
    {
      mode = "n";
      key = "<leader>fg";
      options.desc = "Grep Files";
      action = "<cmd>lua require('telescope.builtin').live_grep({hidden = true})<CR>";
    }
    {
      mode = "n";
      key = "<leader>fb";
      options.desc = "Find Buffer";
      action = "<cmd>lua require('telescope.builtin').buffers()<CR>";
    }
    {
      mode = "n";
      key = "<leader>fh";
      options.desc = "Find Help";
      action = "<cmd>lua require('telescope.builtin').help_tags()<CR>";
    }
    {
      mode = "n";
      key = "<leader>fd";
      options.desc = "Find Diagnostics";
      action = "<cmd>lua require('telescope.builtin').diagnostics()<CR>";
    }
    {
      mode = "n";
      key = "<leader>ft";
      options.desc = "Find Treesitter";
      action = "<cmd>lua require('telescope.builtin').treesitter()<CR>";
    }
  ];
}
