{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.mcp;
  mcp-nixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.mcp = {
    enable = lib.mkEnableOption "MCP (Model Context Protocol) server configurations";
  };

  config = lib.mkIf cfg.enable {
    # Install mcp-nixos package
    home.packages = [ mcp-nixos ];

    # Create MCP configuration for Claude Code (user scope)
    home.file.".config/claude/mcp.json" = {
      text = builtins.toJSON {
        mcpServers = {
          # NixOS package search and info
          nixos = {
            command = "${mcp-nixos}/bin/mcp-nixos";
            args = [ ];
          };

          # Filesystem operations
          filesystem = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-filesystem" "/home/${config.user}" ];
          };

          # Git operations
          git = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-git" "--repository" "/home/${config.user}" ];
          };

          # Sequential thinking for complex reasoning
          sequentialthinking = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-sequential-thinking" ];
          };

          # Memory/knowledge persistence
          memory = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-memory" ];
          };

          # Docker container management
          docker = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-docker" ];
          };

          # Kubernetes cluster operations
          kubernetes = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-kubernetes" ];
          };

          # GitHub repository operations
          # Uncomment and add token if needed:
          # github = {
          #   command = "${pkgs.uv}/bin/uvx";
          #   args = [ "mcp-server-github" ];
          #   env = {
          #     GITHUB_TOKEN = "your-github-token-here";
          #   };
          # };

          # Obsidian vault operations
          obsidian = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-obsidian" "--vault-path" "/home/${config.user}/Documents/Main" ];
          };

          # HTTP fetch for web/API requests
          fetch = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-fetch" ];
          };

          # Brave Search (web search)
          # Uncomment and add API key if needed:
          # brave-search = {
          #   command = "${pkgs.uv}/bin/uvx";
          #   args = [ "mcp-server-brave-search" ];
          #   env = {
          #     BRAVE_API_KEY = "your-api-key-here";
          #   };
          # };
        };
      };
    };
  };
}
