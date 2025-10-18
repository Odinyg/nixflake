{
  programs.nixvim = {
    plugins.render-markdown = {
      enable = true;
      settings = {
        enabled = true;
        file_types = ["markdown"];
        heading = {
          enabled = true;
          icons = ["# " "## " "### " "#### " "##### " "###### "];
        };
        code = {
          enabled = true;
          style = "full";
        };
        bullet = {
          enabled = true;
          icons = ["•" "◦" "▸" "▹"];
        };
        checkbox = {
          enabled = true;
          unchecked = {
            icon = "☐ ";
          };
          checked = {
            icon = "☑ ";
          };
        };
      };
    };
  };
}