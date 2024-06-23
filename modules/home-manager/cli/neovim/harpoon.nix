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
        {
        mode = "n";
        key = "<leader>mh";
        action = "<cmd>lua require('harpoon.ui').nav_file(1)<CR>";

        }
        {
        mode = "n";
        key = "<leader>mj";
        action = "<cmd>lua require('harpoon.ui').nav_file(2)<CR>";
        }
        {
        mode = "n";
        key = "<leader>mk";
        action = "<cmd>lua require('harpoon.ui').nav_file(3)<CR>";
        }
        {
        mode = "n";
        key = "<leader>ml";
        action = "<cmd>lua require('harpoon.ui').nav_file(4)<CR>";
        }
      ];
    plugins = {
      harpoon.enable = true; 
    };
  };
}
