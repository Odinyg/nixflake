{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.forgejo-runner;
in
{
  options.server.forgejo-runner = {
    enable = lib.mkEnableOption "Forgejo Actions runner";
    url = lib.mkOption {
      type = lib.types.str;
      default = "https://git.pytt.io";
      description = "URL of the Forgejo instance to register with";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.forgejo_runner_token = { };

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.default = {
        enable = true;
        name = config.networking.hostName;
        url = cfg.url;
        tokenFile = config.sops.secrets.forgejo_runner_token.path;
        labels = [
          "ubuntu-latest:docker://node:20-bullseye"
          "ubuntu-22.04:docker://node:20-bullseye"
        ];
      };
    };

    virtualisation.docker.enable = true;

    systemd.services.gitea-runner-default = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
  };
}
