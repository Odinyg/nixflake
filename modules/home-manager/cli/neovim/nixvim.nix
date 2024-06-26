{ ...}:
{
   
  programs.nixvim = {
    colorschemes.nord.settings.disable_background = true;
    globals.mapleader = " ";
    enable = true;
    colorschemes.nord.enable = true;
    clipboard.register = "unnamedplus";
    clipboard.providers.wl-copy.enable = true;
   opts = { 
      number = true;
    relativenumber = true;
      shiftwidth = 2;
      smartcase = true;
      smartindent = true;
      expandtab = true;
      tabstop = 4;
      scrolloff = 8;
      };
    viAlias = true;
    vimAlias = true;   

    plugins = {
#      obsidian.enable = true;
      noice.cmdline.enabled = true;
      lint = {
        enable = true;
        lintersByFt =   {
    text = ["vale"];
    json = ["jsonlint"];
    markdown = ["vale"];
    rst = ["vale"];
    ruby = ["ruby"];
    janet = ["janet"];
    inko = ["inko"];
    clojure = ["clj-kondo"];
    dockerfile = ["hadolint"];
    terraform = ["tflint"];
    nix = ["nix"];
  };
  #
      };
      autoclose.enable = true;
      comment.enable = true;
      tmux-navigator.enable = true;
      nix.enable = true;
      mini.enable = true;
      which-key.enable = true;
      lualine = {
        enable = true;
      };
      indent-blankline = {
        enable = true;
        settings.whitespace.remove_blankline_trail = true;
  };
      telescope = {
      enable = true;
      };
      treesitter = {
      enable = true;
      nixGrammars = true;
      nixvimInjections = true;
      };
      harpoon.enable = true;

      };
    };
}
