{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.mcp;
  mcp-nixos = inputs.mcp-nixos.packages.${pkgs.system}.default;
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
          nixos = {
            command = "${mcp-nixos}/bin/mcp-nixos";
            args = [ ];
          };
        };
      };
    };
  };
}
