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

  ];

}
