       
{
  programs.nixvim.maps = {
    normal = {

      "<leader>w" = {
        desc = "Save";
        action = "<cmd>w<CR>";
        silent = true;
      };
      "<leader>t" = {
        desc = "toggleterm";
        action = "<cmd>ToggleTerm direction=float<cr>";
        silent = true;
      };

      "<leader>q" = {
        desc = "Quit";
        action = "<cmd>q<CR>";
        silent = true;
      };
    };
    visual = {
      ">" = ">gv";
      "<" = "<gv";
    };
  };

}
