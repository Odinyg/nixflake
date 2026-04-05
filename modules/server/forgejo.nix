{
  config,
  lib,
  ...
}:
let
  cfg = config.server.forgejo;
in
{
  options.server.forgejo = {
    enable = lib.mkEnableOption "Forgejo git forge";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for the Forgejo web interface";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "git.pytt.io";
      description = "Public domain for Forgejo";
    };
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "PostgreSQL host for Forgejo";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.forgejo_admin_password = {
      owner = "forgejo";
    };
    sops.secrets.postgresql_forgejo_password = { };

    sops.templates."forgejo-env".content = ''
      FORGEJO__database__PASSWD=${config.sops.placeholder.postgresql_forgejo_password}
    '';

    services.forgejo = {
      enable = true;
      database = {
        type = "postgres";
        host = cfg.dbHost;
        name = "forgejo";
        user = "forgejo";
        createDatabase = false;
      };
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}/";
          HTTP_PORT = cfg.port;
          HTTP_ADDR = "0.0.0.0";
          SSH_DOMAIN = cfg.domain;
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
          BUILTIN_SSH_SERVER_USER = "git";
        };
        repository = {
          ENABLE_PUSH_CREATE_USER = true;
          ENABLE_PUSH_CREATE_ORG = true;
        };
        service = {
          DISABLE_REGISTRATION = true;
          REQUIRE_SIGNIN_VIEW = true;
        };
        security = {
          INSTALL_LOCK = true;
          PASSWORD_HASH_ALGO = "argon2";
          MIN_PASSWORD_LENGTH = 12;
        };
        session = {
          COOKIE_SECURE = true;
        };
        webhook = {
          ALLOWED_HOST_LIST = "10.10.30.110,10.10.30.112,ntfy.pytt.io";
        };
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };
      };
      dump = {
        enable = true;
        interval = "06:00";
        type = "tar.zst";
      };
    };

    systemd.services.forgejo = {
      serviceConfig.EnvironmentFile = config.sops.templates."forgejo-env".path;
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
      after = [
        "postgresql.service"
        "postgresql-set-passwords.service"
      ];
    };

    systemd.services.forgejo-admin-setup = {
      description = "Provision Forgejo admin user";
      after = [ "forgejo.service" ];
      requires = [ "forgejo.service" ];
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
      environment = {
        FORGEJO_CUSTOM = config.services.forgejo.customDir;
        FORGEJO_WORK_DIR = config.services.forgejo.stateDir;
        HOME = config.services.forgejo.stateDir;
        USER = "forgejo";
      };
      serviceConfig = {
        Type = "oneshot";
        User = "forgejo";
        RemainAfterExit = true;
      };
      script = ''
        ${config.services.forgejo.package}/bin/forgejo admin user create \
          --admin \
          --email "admin@${cfg.domain}" \
          --username odin \
          --password "$(tr -d '\n' < ${config.sops.secrets.forgejo_admin_password.path})" \
          || true
      '';
    };

    # Dump service — part of homelab target so it stops cleanly with the homelab
    systemd.services.forgejo-dump = {
      partOf = [ "homelab.target" ];
    };
  };
}
