{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}:
let
  standalone = !(options ? nixpkgs);

  mcp-nixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default;

  mcpFileConfig = {
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

  hmConfigNixOS = {
    home.packages = [ mcp-nixos ];

    # Load GitHub token from sops-decrypted secret for Claude Code MCP
    home.sessionVariablesExtra = ''
      if [ -r /run/secrets/github_token ]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat /run/secrets/github_token)"
      fi
    '';

    home.file.".config/claude/mcp.json" = {
      text = builtins.toJSON mcpFileConfig;
    };
  };

  standaloneSecretPath =
    if
      config ? sops
      && config.sops ? secrets
      && config.sops.secrets ? github_token
      && config.sops.secrets.github_token ? path
    then
      config.sops.secrets.github_token.path
    else
      "/run/user/1000/secrets/github_token";

  hmConfigStandalone = hmConfigNixOS // {
    home.sessionVariablesExtra = ''
      if [ -r ${standaloneSecretPath} ]; then
        export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${standaloneSecretPath})"
      fi
    '';
  };
in
{
  options.mcp = {
    enable = lib.mkEnableOption "MCP (Model Context Protocol) server configurations";
  };

  config = lib.mkMerge (
    [
      {
        home-manager.users.${config.user} = lib.mkIf config.mcp.enable hmConfigNixOS;
      }
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.mcp.enable hmConfigStandalone)
    ]
  );
}
