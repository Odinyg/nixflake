{
      programs.nixvim = {
      plugins.flash.enable = true;
      keymaps = [
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
      action = "<cmd>lua require('flash').toggle()<cr>";
      options.desc = "";
      mode = "n";
    }
  ];
};
}
