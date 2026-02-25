{ config, lib, pkgs, inputs, ... }:
let
  mcp-nixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.mcp = {
    enable = lib.mkEnableOption "MCP (Model Context Protocol) server configurations";
  };

  config.home-manager.users.${config.user} = lib.mkIf config.mcp.enable {
    home.packages = [ mcp-nixos ];

    home.file.".config/claude/mcp.json" = {
      text = builtins.toJSON {
        mcpServers = {
          nixos = {
            command = "${mcp-nixos}/bin/mcp-nixos";
            args = [ ];
          };

          filesystem = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-filesystem" "/home/${config.user}" ];
          };

          git = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-git" "--repository" "/home/${config.user}" ];
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
            args = [ "mcp-server-obsidian" "--vault-path" "/home/${config.user}/Documents/Main" ];
          };

          fetch = {
            command = "${pkgs.uv}/bin/uvx";
            args = [ "mcp-server-fetch" ];
          };

        };
      };
    };
  };
}
