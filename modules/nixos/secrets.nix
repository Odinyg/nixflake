{ config, lib, ... }:
let
  cfg = config.secrets;
in
{
  options = {
    secrets = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable secrets management with sops-nix";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure sops-nix
    sops = {
      age.keyFile = "/home/${config.user}/.config/sops/age/keys.txt";

      # Default sops file
      defaultSopsFile = ../../secrets/secrets.yaml;

      # Validate sops files at build time
      validateSopsFiles = false; # Set to true once you've generated host keys

      # Define secrets to be decrypted
      secrets = {
        # SSH private keys — deployed to user's ~/.ssh/
        "ssh_keys/id_ed25519_sk" = {
          owner = config.user;
          mode = "0600";
          path = "/home/${config.user}/.ssh/id_ed25519_sk";
        };
        "ssh_public_keys/id_ed25519_sk" = {
          owner = config.user;
          mode = "0644";
          path = "/home/${config.user}/.ssh/id_ed25519_sk.pub";
        };
        "ssh_certs/id_ed25519_sk-cert" = {
          owner = config.user;
          mode = "0644";
          path = "/home/${config.user}/.ssh/id_ed25519_sk-cert.pub";
        };
        # GitHub personal access token for Claude Code MCP
        "github_token" = {
          owner = config.user;
          mode = "0400";
        };
      }
      // lib.optionalAttrs config.smbmount.enable {
        # SMB credentials for NAS mounting (only when smbmount is enabled)
        "smb/credentials" = {
          owner = "root";
          mode = "0600";
          path = "/etc/nixos/smb-secrets";
        };
      };
    };

  };
}
