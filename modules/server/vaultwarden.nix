{
  config,
  lib,
  ...
}:
let
  cfg = config.server.vaultwarden;
in
{
  options.server.vaultwarden = {
    enable = lib.mkEnableOption "Vaultwarden password manager";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8222;
      description = "Port for the Vaultwarden web interface";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "vault.pytt.io";
      description = "Public domain for Vaultwarden";
    };
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "PostgreSQL host for Vaultwarden";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.postgresql_vaultwarden_password = { };
    sops.secrets.vaultwarden_admin_token = { };

    sops.templates."vaultwarden-env".content = ''
      DATABASE_URL=postgresql://vaultwarden:${config.sops.placeholder.postgresql_vaultwarden_password}@${cfg.dbHost}:5432/vaultwarden
      ADMIN_TOKEN=${config.sops.placeholder.vaultwarden_admin_token}
    '';

    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      config = {
        DOMAIN = "https://${cfg.domain}";
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = cfg.port;
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = true;
        SHOW_PASSWORD_HINT = false;
      };
      environmentFile = config.sops.templates."vaultwarden-env".path;
    };

    systemd.services.vaultwarden = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
      after = [
        "postgresql.service"
        "postgresql-set-passwords.service"
      ];
    };

  };
}
