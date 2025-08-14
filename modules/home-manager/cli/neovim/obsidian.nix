{

  programs.nixvim = {
    plugins.obsidian = {
      enable = true;
      settings = {
        completion = {
          min_chars = 2;
          nvim_cmp = true;
        };
        new_notes_location = "notes_subdir";
        daily_notes = {
          folder = "dailyNotes";
          date_format = "%Y-%m-%d";
          alias_format = "%B %-d, %Y";
        };
        workspaces = [
          {
            name = "main";
            path = "~/Documents/Main";
          }
        ];
        opts = {
          legacy_commands = false;
        };
      };
    };

    keymaps = [
      {
        key = "<leader>od";
        action = "<cmd>ObsidianToday<cr>";
        options.desc = "obsidian [d]aily";
        mode = "n";
      }
      {
        key = "<leader>oy";
        action = "<cmd>ObsidianToday -1<cr>";
        options.desc = "obsidian [y]esterday";
        mode = "n";
      }
      {
        key = "<leader>ob";
        action = "<cmd>ObsidianBacklinks<cr>";
        options.desc = "obsidian [b]acklinks";
        mode = "n";
      }
      {
        key = "<leader>ol";
        action = "<cmd>ObsidianLink<cr>";
        options.desc = "obsidian [l]ink selection";
        mode = "n";
      }
      {
        key = "<leader>of";
        action = "<cmd>ObsidianFollowLink<cr>";
        options.desc = "obsidian [f]ollow link";
        mode = "n";
      }
      {
        key = "<leader>on";
        action = "<cmd>ObsidianNew<cr>";
        options.desc = "obsidian [n]ew";
        mode = "n";
      }
      {
        key = "<leader>os";
        action = "<cmd>ObsidianSearch<cr>";
        options.desc = "obsidian [s]earch";
        mode = "n";
      }
      {
        key = "<leader>oq";
        action = "<cmd>ObsidianQuickSwitch<cr>";
        options.desc = "obsidian [q]uick switch";
        mode = "n";
      }
      {
        key = "<leader>oO";
        action = "<cmd>ObsidianOpen<cr>";
        options.desc = "obsidian [O]pen in app";
        mode = "n";
      }

    ];
  };
}
