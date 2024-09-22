{
  programs.nixvim = {
    plugins.harpoon.enable = true;
    keymaps = [
      {
        mode = "n";
        key = "<leader>mm";
        action = "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>";
        options.desc = "Harpoon Quick Menu";
      }
      {
        mode = "n";
        key = "<leader>ma";
        action = "<cmd>lua require('harpoon.mark').add_file()<CR>";
        options.desc = "Add file Harpoon buffer";

      }
      {
        mode = "n";
        key = "<leader>mn";
        action = "<cmd>lua require('harpoon.ui').nav_next()<CR>";
        options.desc = "Next file harpoon";
      }
      {
        mode = "n";
        key = "<leader>mp";
        action = "<cmd>lua require('harpoon.ui').nav_prev()<CR>";
        options.desc = "Previous file harpoon";
      }
      {
        mode = "n";
        key = "<C-1>";
        action = "<cmd>lua require('harpoon.ui').nav_file(1)<CR>";
        options.desc = "File 1 harpoon";
        options.remap = true;

      }
      {
        mode = "n";
        key = "<C-2>";
        action = "<cmd>lua require('harpoon.ui').nav_file(2)<CR>";
        options.desc = "File 2 harpoon";
        options.remap = true;
      }
      {
        mode = "n";
        key = "<C-3>";
        action = "<cmd>lua require('harpoon.ui').nav_file(3)<CR>";
        options.desc = "File 3 harpoon";
        options.remap = true;
      }
      {
        mode = "n";
        key = "<C-4>";
        action = "<cmd>lua require('harpoon.ui').nav_file(4)<CR>";
        options.desc = "File 4 harpoon";
        options.remap = true;
      }
    ];
  };
}
