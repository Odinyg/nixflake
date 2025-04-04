{
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      gopls.enable = true;
      bashls.enable = true;
      cmake.enable = true;
      lua_ls.enable = true;
      nil_ls = {
        enable = true;
        autostart = true;
      };
      terraformls.enable = true;
      csharp_ls.enable = true;
      eslint.enable = true;
      html.enable = true;
      yamlls.enable = true;
      pyright.enable = true;

    };
    keymaps.lspBuf = {
      "gd" = "definition";
      "gD" = "references";
      "gt" = "type_definition";
      "gi" = "implementation";
      "K" = "hover";
    };
  };
}
