{ ... }:
{

  programs.nixvim = {
    colorschemes.nord.settings.disable_background = true;
    globals.mapleader = " ";
    enable = true;
    colorschemes.nord.enable = true;
    clipboard.register = "unnamedplus";
   clipboard.providers.xclip.enable= true;
    opts = {
      conceallevel = 2;
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
      flash.enable = true;
      noice.cmdline.enabled = true;
      lint = {
        enable = true;
        lintersByFt = {
          text = [ "vale" ];
          json = [ "jsonlint" ];
          markdown = [ "vale" ];
          rst = [ "vale" ];
          ruby = [ "ruby" ];
          janet = [ "janet" ];
          inko = [ "inko" ];
          clojure = [ "clj-kondo" ];
          dockerfile = [ "hadolint" ];
          terraform = [ "tflint" ];
          nix = [ "nix" ];
        };
        #
      };
      autoclose.enable = true;
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
