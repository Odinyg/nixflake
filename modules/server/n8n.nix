{
  config,
  lib,
  ...
}:
let
  cfg = config.server.n8n;
in
{
  options.server.n8n = {
    enable = lib.mkEnableOption "n8n workflow automation";
    port = lib.mkOption {
      type = lib.types.port;
      default = 5678;
      description = "Port for the n8n web interface";
    };
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.20";
      description = "PostgreSQL host for n8n";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.n8n_db_password = { };

    sops.templates."n8n-env".content = ''
      DB_TYPE=postgresdb
      DB_POSTGRESDB_HOST=${cfg.dbHost}
      DB_POSTGRESDB_PORT=5432
      DB_POSTGRESDB_DATABASE=n8n
      DB_POSTGRESDB_USER=n8n
      DB_POSTGRESDB_PASSWORD=${config.sops.placeholder.n8n_db_password}
      N8N_SECURE_COOKIE=false
      N8N_METRICS=true
      GENERIC_TIMEZONE=Europe/Oslo
    '';

    services.n8n = {
      enable = true;
      openFirewall = false;
    };

    systemd.services.n8n.serviceConfig.EnvironmentFile = config.sops.templates."n8n-env".path;

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
