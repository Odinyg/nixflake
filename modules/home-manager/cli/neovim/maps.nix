{
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>w";
      action = "<cmd>w<CR>";
    }
    {
      mode = "n";
      key = "<leader>q";
      action = "<cmd>q<CR>";
    }
    {
      key = "<C-g>";
      action = "<cmd>LazyGit<cr>";
      options.desc = "Lazygit";
      mode = "n";
    }
    {
      key = "<leader>lg";
      action = "<cmd>LazyGit<cr>";
      options.desc = "Lazygit";
      mode = "n";
    }
    {
      key = "<leader>s";
      action = "<cmd>!~/.config/nixvim/scripts/scratchpad.sh<cr>";
      options.desc = "Open scratchpad";
      mode = "n";
    }
    {
      key = "<D-g>";
      action = "<cmd>!~/.config/nixvim/scripts/scratchpad.sh<cr>";
      options.desc = "Open scratchpad (Super+G)";
      mode = "n";
    }

  ];

}
