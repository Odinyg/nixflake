{

  programs.nixvim.plugins.mini = {
    enable = true;
    mockDevIcons = true;
    autoLoad = true;
    modules = {
      ai = {
        n_lines = 100;
        search_method = "cover_or_next";
      };
      comment = { };
      completion = { };

      bracketed = { };
      files = { };
      icons = { };
      # jump = { };
      # indentscope = { };
      trailspace = { };
      map = { };
      tabline = { };
      git = { };
      surround = { };
      statusline = { };
      starter = { };
      splitjoin = { };
      jump = { };
      pairs = { };

    };

  };

}
