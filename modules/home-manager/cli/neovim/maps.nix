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

  ];

}
