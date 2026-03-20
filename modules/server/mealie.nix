{
  config,
  lib,
  ...
}:
let
  cfg = config.server.mealie;
in
{
  options.server.mealie = {
    enable = lib.mkEnableOption "Mealie recipe and meal planning app (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9925;
      description = "Host port for the Mealie web interface";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for Mealie";
    };
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.20";
      description = "PostgreSQL host for Mealie";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.postgresql_mealie_password = { };
    sops.secrets.mealie_oidc_client_secret = { };

    sops.templates."mealie-env".content = ''
      BASE_URL=https://mealie.${cfg.domain}
      DB_ENGINE=postgres
      POSTGRES_USER=mealie
      POSTGRES_PASSWORD=${config.sops.placeholder.postgresql_mealie_password}
      POSTGRES_SERVER=${cfg.dbHost}
      POSTGRES_PORT=5432
      POSTGRES_DB=mealie
      OIDC_AUTH_ENABLED=true
      OIDC_SIGNUP_ENABLED=true
      OIDC_CONFIGURATION_URL=https://auth.${cfg.domain}/.well-known/openid-configuration
      OIDC_CLIENT_ID=mealie
      OIDC_CLIENT_SECRET=${config.sops.placeholder.mealie_oidc_client_secret}
      OIDC_AUTO_REDIRECT=true
      OIDC_ADMIN_GROUP=admins
      OIDC_USER_GROUP=Home
    '';

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.mealie = {
      image = "ghcr.io/mealie-recipes/mealie:v3.12.0";
      environmentFiles = [ config.sops.templates."mealie-env".path ];
      volumes = [
        "/var/lib/homelab/mealie/data:/app/data"
      ];
      ports = [ "${toString cfg.port}:9000" ];
      extraOptions = [ "--network=iowa" ];
    };

    systemd.services.docker-mealie = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d /var/lib/homelab/mealie 0755 root root -"
      "d /var/lib/homelab/mealie/data 0755 root root -"
    ];
  };
}
