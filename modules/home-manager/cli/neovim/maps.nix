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
      mode = "n";
      key =" <leader>on"; 
      action = "<cmd>ObsidianNew<cr>";
      options.desc = "New Obsidian note"; 

    }
    { 
      key = "<leader>oo";
      action = "<cmd>ObsidianSearch<cr>";
      options.desc = "Search Obsidian notes";
      mode = "n";
    }
    { 
      key = "<leader>os";
      action = "<cmd>ObsidianQuickSwitch<cr>";
      options.desc = "Quick Switch";
      mode = "n";
    }

    { 
      key = "<leader>ot";
      action = "<cmd>ObsidianTemplate<cr>";
      options.desc = "Follow link under cursor";
      mode = "n";
    }

    { 
      key = "<leader>ob";
      action = "<cmd>ObsidianBacklinks<cr>";
      options.desc = "Show location list of backlinks";
      mode = "n";
    }
    { 
      key = "s";
      action = "<cmd>lua require('flash').jump()<cr>";
      options.desc = "Flash";
      mode = "n";
    }
    { 
      key = "S";
      action = "<cmd>lua require('flash').treesitter()<cr>";
      options.desc = "Flash Treesitter";
      mode = "n";
    }
    { 
      key = "<c-s>";
      action = "<cmd>require('flash').toggle()<cr>";
      options.desc = "";
      mode = "n";
    }

  ];
  # ">" = ">gv";
  # "<" = "<gv";

}
