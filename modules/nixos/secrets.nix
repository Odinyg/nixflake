{ config, lib, ... }:
{
  options = {
    secrets = {
      enable = lib.mkEnableOption {
        description = "Enable secrets management with sops-nix";
        default = false;
      };
    };
  };

  config = lib.mkIf config.secrets.enable {
    # Configure sops-nix
    sops = {
      # Path to the age key for decryption
      age.keyFile = "/var/lib/sops-nix/key.txt";

      # Default sops file
      defaultSopsFile = ../../secrets/secrets.yaml;

      # Validate sops files at build time
      validateSopsFiles = false; # Set to true once you've generated host keys

      # Define secrets to be decrypted
      secrets = {
        # SSH keys
        "ssh_keys/personal_key" = {
          owner = config.user;
          path = "/home/${config.user}/.ssh/id_personal";
          mode = "0600";
        };

        "ssh_keys/work_key" = {
          owner = config.user;
          path = "/home/${config.user}/.ssh/id_work";
          mode = "0600";
        };

        "ssh_public_keys/personal_key" = {
          owner = config.user;
          path = "/home/${config.user}/.ssh/id_personal.pub";
          mode = "0644";
        };

        "ssh_public_keys/work_key" = {
          owner = config.user;
          path = "/home/${config.user}/.ssh/id_work.pub";
          mode = "0644";
        };

        # SMB credentials for NAS mounting
        "smb/credentials" = {
          owner = "root";
          mode = "0600";
          path = "/etc/nixos/smb-secrets";
        };
      };
    };

    # Ensure .ssh directory exists with correct permissions
    system.activationScripts.setupSSHDir = lib.mkAfter ''
      mkdir -p /home/${config.user}/.ssh
      chown ${config.user}:users /home/${config.user}/.ssh
      chmod 700 /home/${config.user}/.ssh
    '';
  };
}
