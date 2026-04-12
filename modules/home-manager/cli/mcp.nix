{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.mcp;
  mcp-nixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.mcp = {
    enable = lib.mkEnableOption "MCP (Model Context Protocol) server configurations";
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.packages = [ mcp-nixos ];

    # Load GitHub token from sops-decrypted secret for Claude Code MCP
    home.sessionVariablesExtra = ''
      if [ -r /run/secrets/github_token ]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat /run/secrets/github_token)"
      fi
    '';

    home.file.".config/claude/mcp.json" = {
      text = builtins.toJSON {
        mcpServers = {
          nixos = {
            command = "${mcp-nixos}/bin/mcp-nixos";
            args = [ ];
          };

          filesystem = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "mcp-server-filesystem"
              "/home/${config.user}"
            ];
          };

          git = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "mcp-server-git"
              "--repository"
              "/home/${config.user}"
            ];
          };

          sequentialthinking = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-sequential-thinking" ];
          };

          memory = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-memory" ];
          };

          docker = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-docker" ];
          };

          kubernetes = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-kubernetes" ];
          };

          obsidian = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "mcp-server-obsidian"
              "--vault-path"
              "/home/${config.user}/Documents/Main"
            ];
          };

          fetch = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-fetch" ];
          };

          github = {
            command = "${pkgs.gh}/bin/gh";
            args = [
              "mcp"
              "serve"
            ];
          };

          context7 = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@upstash/context7-mcp"
            ];
          };

          playwright = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [ "@playwright/mcp@latest" ];
          };

        };
      };
    };
  };
}
