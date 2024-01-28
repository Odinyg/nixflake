{
  programs.nixvim.plugins.telescope = {
    enable = true;
    defaults = {
      file_ignore_patterns = [
        "^.git/"
        "^output/"
        "^target/"
      ];
    };
  };
  programs.nixvim.keymaps =[
        {
        mode = "n";
        key = "<leader>ff";
        #desc = "Find Files";
        action = "<cmd>lua require('telescope.builtin').find_files({hidden = true})<CR>";
        }
        {
        mode = "n";
        key ="<leader>fg"; 
        #desc = "Grep Files";
        action = "<cmd>lua require('telescope.builtin').live_grep({hidden = true})<CR>";
        }
        {
        mode = "n";
        key = "<leader>fb"; 
        #desc = "Find Buffer";
        action = "<cmd>lua require('telescope.builtin').buffers()<CR>";
        }
        {
        mode = "n";
        key = "<leader>fh";
        #desc = "Find Help";
        action = "<cmd>lua require('telescope.builtin').help_tags()<CR>";
        }
        {
        mode = "n";
        key = "<leader>fd"; 
        #desc = "Find Diagnostics";
        action = "<cmd>lua require('telescope.builtin').diagnostics()<CR>";
        }
        {
        mode = "n";
        key = "<leader>ft";
        #desc = "Find Treesitter";
        action = "<cmd>lua require('telescope.builtin').treesitter()<CR>";
        }
      ];
}
