{
  programs.nixvim = {
    plugins.auto-save = {
      enable = true;
      settings = {
        enabled = true;
        trigger_events = {
          immediate_save = ["BufLeave" "FocusLost"];
          defer_save = ["InsertLeave" "TextChanged"];
          cancel_deferred_save = ["InsertEnter"];
        };
        condition = ''
          function(buf)
            local fn = vim.fn
            local utils = require("auto-save.utils.data")
            local filetype = fn.getbufvar(buf, "&filetype")

            if fn.getbufvar(buf, "&modifiable") == 1 and
               utils.not_in(filetype, {}) and
               fn.getbufvar(buf, "&readonly") == 0 and
               (filetype == "markdown" or filetype == "md") then
              return true
            end
            return false
          end
        '';
        write_all_buffers = false;
        debounce_delay = 30000;
        callbacks = {
          enabling = null;
          disabling = null;
          before_asserting_save = null;
          before_saving = null;
          after_saving = null;
        };
      };
    };

    keymaps = [
      {
        key = "<leader>as";
        action = "<cmd>ASToggle<cr>";
        options.desc = "[a]uto [s]ave toggle";
        mode = "n";
      }
    ];
  };
}