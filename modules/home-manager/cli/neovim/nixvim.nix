{ pkgs, ... }: {
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";

    extraPackages = with pkgs; [
      # Formatters for conform.nvim
      prettierd
      nodePackages.prettier
      black
      stylua
      nixfmt-rfc-style
      yamlfmt
    ];

    colorschemes = {
      nord.enable = true;
      nord.settings.disable_background = true;
    };

    clipboard = {
      register = "unnamedplus";
      providers.xclip.enable = true;
    };

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
      zellij-nav = {
        autoLoad = true;
        enable = true;
      };
      zellij.enable = true;
      web-devicons.enable = true;
      cmp_yanky.enable = true;
      lazygit.enable = true;

      noice.settings.cmdline.enabled = true;
      autoclose.enable = false;
      comment.enable = true;
      nix.enable = true;
      mini.enable = true;
      which-key.enable = true;
      lualine = { enable = true; };
      indent-blankline = { enable = true; };
      treesitter = {
        enable = true;
        nixGrammars = true;
        nixvimInjections = true;
      };
      harpoon.enable = true;

    };

    extraPlugins = with pkgs.vimPlugins; [ opencode-nvim ];
  };
}
