{ pkgs, ... }:
{
  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    settings = {

      format_on_save = {
        lspFallback = true;
        timeoutMs = 500;
      };
      notify_on_error = true;

      formatters = {
        prettier = {
          prepend_args = [ "--preserve-blank-lines" ];
        };
        prettierd = {
          prepend_args = [ "--preserve-blank-lines" ];
        };
        yamlfmt = {
          prepend_args = [
            "-formatter"
            "retain_line_breaks=true,retain_line_breaks_single=true"
          ];
        };
      };

      formatters_by_ft = {
        liquidsoap = [ "liquidsoap-prettier" ];
        html = {
          __unkeyed-1 = "prettierd";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        css = {
          __unkeyed-1 = "prettierd";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        javascript = {
          __unkeyed-1 = "prettierd";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        javascriptreact = {
          __unkeyed-1 = "prettierd";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        typescript = {
          __unkeyed-1 = "prettierd";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        typescriptreact = {
          __unkeyed-1 = "prettierd";
          __unkeyed-2 = "prettier";
          stop_after_first = true;
        };
        python = [ "black" ];
        lua = [ "stylua" ];
        nix = [ "nixfmt" ];
        markdown = {
          __unkeyed-1 = "prettier";
          __unkeyed-2 = "prettierd";
          stop_after_first = true;
        };
        yaml = [
          "yamllint"
          "yamlfmt"
        ];
        terragrunt = [
          "hcl"
        ];
      };
    };
  };
}
