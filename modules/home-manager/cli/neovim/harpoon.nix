{
  programs.nixvim = {
      keymaps = [
        {
        mode = "n";
        key = "<leader>mm";
        action = "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>";
        }
        {
        mode = "n";
        key = "<leader>ma";
        action = "<cmd>lua require('harpoon.mark').add_file()<CR>";
        }
        {
        mode = "n";
        key = "<leader>mn";
        action = "<cmd>lua require('harpoon.ui').nav_next()<CR>";
        }
        {
        mode = "n";
        key = "<leader>mp";
        action = "<cmd>lua require('harpoon.ui').nav_prev()<CR>";
        }
      ];
    plugins = {
      harpoon.enable = true; 
    };
  };
}
