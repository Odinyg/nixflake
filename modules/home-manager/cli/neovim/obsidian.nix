{

      obsidian = {
        enable = true;
        settings =
        {
          completion = {
            min_chars = 2;
            nvim_cmp = true;
          };
          new_notes_location = "current_dir";
          workspaces = [
            {
              name = "main";
              path = "~/Documents/Main";
            }
          ];
      };
      };
  programs.nixvim.keymaps = [

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

  ];
  }
