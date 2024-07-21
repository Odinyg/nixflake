{
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>w";
      #desc = "Save";
      action = "<cmd>w<CR>";
      #  silent = true;
    }
    #{
    #        mode = "n";
    #        key = "<leader>t";
    #desc = "toggleterm";
    #        action = "<cmd>ToggleTerm direction=float<cr>";
    #  silent = true;
    # }
    {
      mode = "n";
      key = "<leader>q";
      #desc = "Quit";
      action = "<cmd>q<CR>";
      #  silent = true;
    }
  ];
  # ">" = ">gv";
  # "<" = "<gv";

}
