{
  config,
  lib,
  ...
}:
let
  cfg = config.server.norish;
in
{
  options.server.norish = {
    enable = lib.mkEnableOption "Norish recipe app (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for the Norish web interface";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for Norish";
    };
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.20";
      description = "PostgreSQL host for Norish";
    };
    redisPort = lib.mkOption {
      type = lib.types.port;
      default = 6380;
      description = "Port for the dedicated Norish Redis instance";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.postgresql_norish_password = { };
    sops.secrets.norish_master_key = { };
    sops.secrets.norish_oidc_client_secret = { };
    sops.secrets.redis_pass = { };

    sops.templates."norish-env".content = ''
      AUTH_URL=https://norish.${cfg.domain}
      DATABASE_URL=postgres://norish:${config.sops.placeholder.postgresql_norish_password}@${cfg.dbHost}:5432/norish
      MASTER_KEY=${config.sops.placeholder.norish_master_key}
      REDIS_URL=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:${toString cfg.redisPort}
      OIDC_NAME=Authelia
      OIDC_ISSUER=https://auth.${cfg.domain}
      OIDC_CLIENT_ID=norish
      OIDC_CLIENT_SECRET=${config.sops.placeholder.norish_oidc_client_secret}
      TRUSTED_ORIGINS=https://norish.${cfg.domain}
    '';

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.norish = {
      image = "norishapp/norish:latest";
      environmentFiles = [ config.sops.templates."norish-env".path ];
      volumes = [
        "/var/lib/homelab/norish/uploads:/app/uploads"
      ];
      ports = [ "${toString cfg.port}:3000" ];
      extraOptions = [ "--network=iowa" ];
    };

    systemd.services.docker-norish = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    # Redis needs sops secrets decrypted for requirePassFile
    systemd.services.redis-norish = {
      after = [ "sops-nix.service" ];
      requires = [ "sops-nix.service" ];
    };

    # Dedicated Redis instance for Norish
    services.redis.servers.norish = {
      enable = true;
      port = cfg.redisPort;
      bind = "127.0.0.1";
      requirePassFile = config.sops.secrets.redis_pass.path;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d /var/lib/homelab/norish 0755 root root -"
      "d /var/lib/homelab/norish/uploads 0755 root root -"
    ];
  };
}
