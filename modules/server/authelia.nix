{
  config,
  lib,
  ...
}:
let
  cfg = config.server.authelia;
in
{
  options.server.authelia = {
    enable = lib.mkEnableOption "Authelia SSO authentication";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for Authelia";
    };
    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 9959;
      description = "Port for Authelia metrics";
    };
    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 9091;
      description = "Internal listen port for Authelia";
    };
    redisHost = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.20";
      description = "Redis host for session storage";
    };
    redisPort = lib.mkOption {
      type = lib.types.port;
      default = 30059;
      description = "Redis port for session storage";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.authelia_jwt_secret = {
      owner = "authelia-main";
    };
    sops.secrets.authelia_session_secret = {
      owner = "authelia-main";
    };
    sops.secrets.authelia_storage_encryption_key = {
      owner = "authelia-main";
    };
    sops.secrets.authelia_oidc_hmac_secret = {
      owner = "authelia-main";
    };
    sops.secrets.authelia_session_redis_password = {
      owner = "authelia-main";
    };

    # Users database (hashed passwords — safe in store)
    environment.etc."authelia/users_database.yml" = {
      text = ''
        ---
        users:
          homelab:
            disabled: false
            displayname: Homelab Admin
            email: admin@${cfg.domain}
            password: '$argon2id$v=19$m=65536,t=3,p=4$g/+SvP06elXQTV8r2OeDcQ$l64+8ouJBTYlKjVWHqUqXPwEaLq7U3/pFjG27vC0EKU'
            groups:
              - admins
      '';
      mode = "0440";
      user = "authelia-main";
      group = "authelia-main";
    };

    services.authelia.instances.main = {
      enable = true;
      secrets = {
        jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
        sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
        storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
        oidcHmacSecretFile = config.sops.secrets.authelia_oidc_hmac_secret.path;
        oidcIssuerPrivateKeyFile = "/etc/homelab/authelia/oidc.pem";
      };
      settings = {
        theme = "dark";
        server.address = "tcp://127.0.0.1:${toString cfg.listenPort}";

        telemetry.metrics = {
          enabled = true;
          address = "tcp://0.0.0.0:${toString cfg.metricsPort}";
        };

        log.level = "info";

        webauthn = {
          enable_passkey_login = true;
          display_name = cfg.domain;
          attestation_conveyance_preference = "indirect";
          timeout = "60s";
          selection_criteria.user_verification = "preferred";
        };

        totp.issuer = cfg.domain;

        authentication_backend.file = {
          path = "/etc/authelia/users_database.yml";
          watch = true;
          password = {
            algorithm = "argon2id";
            iterations = 1;
            salt_length = 16;
            parallelism = 8;
            memory = 64;
          };
        };

        session = {
          cookies = [
            {
              domain = cfg.domain;
              authelia_url = "https://auth.${cfg.domain}";
              default_redirection_url = "https://home.${cfg.domain}";
            }
          ];
          redis = {
            host = cfg.redisHost;
            port = cfg.redisPort;
          };
        };

        regulation = {
          max_retries = 3;
          find_time = "2m";
          ban_time = "5m";
        };

        storage.local.path = "/var/lib/authelia-main/db.sqlite3";

        access_control = {
          default_policy = "deny";
          rules = [
            {
              domain = "auth.${cfg.domain}";
              policy = "bypass";
            }
            {
              domain = [
                "pve1.${cfg.domain}"
                "truenas.${cfg.domain}"
              ];
              policy = "one_factor";
              subject = [ "group:admins" ];
            }
            {
              domain = [ "pve2.${cfg.domain}" ];
              policy = "two_factor";
              subject = [ "group:admins" ];
            }
            {
              domain = [ "*.${cfg.domain}" ];
              policy = "one_factor";
            }
          ];
        };

        notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";

        identity_providers.oidc.clients = [
          {
            client_id = "proxmox";
            client_name = "Proxmox VE";
            client_secret = "$pbkdf2-sha512$310000$KkznHtQUFtMFBGIMQnSgEg$hCvt.i.Exo8WSlEAUGdPSu8orXZRqYJZT7k0olWLcQ5LucODH4GLCIJUPx3VESE8L8QqkH0whdk0ep5Rnw57dA";
            public = false;
            authorization_policy = "one_factor";
            redirect_uris = [
              "https://pve1.${cfg.domain}"
              "https://pve2.${cfg.domain}"
            ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            userinfo_signed_response_alg = "none";
          }
          {
            client_id = "norish";
            client_name = "Norish";
            client_secret = "$pbkdf2-sha512$310000$QQL4jfrdXFc6SWtDGut/.w$qsH/9g/YkpMK73A6aLf80x26Vl3VJEZqN/Wwd6HnJ1M6DJf1T4PZloHVibF5tj7iQdxWzhEEe5oaj86qjL.meQ";
            public = false;
            authorization_policy = "one_factor";
            redirect_uris = [ "https://norish.${cfg.domain}/api/auth/oauth2/callback/oidc" ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            userinfo_signed_response_alg = "none";
          }
          {
            client_id = "gatus";
            client_name = "Gatus";
            client_secret = "$pbkdf2-sha512$310000$4ER2edlklu3DXb01L4x/rw$svXMXo1NHy8hDyh62DH3YPA1YKI4mU6ilL6/esaStHfk55IqYs5Cx4xVGzu8nq1VQFYSbrReysTzQgod1Uk9tQ";
            public = false;
            authorization_policy = "one_factor";
            redirect_uris = [ "https://gatus.${cfg.domain}/authorization-code/callback" ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            userinfo_signed_response_alg = "none";
          }
          {
            client_id = "grafana";
            client_name = "Grafana";
            client_secret = "$pbkdf2-sha512$310000$K2HozYqmNUwBDwq2YG86eQ$Z7ZEuA7Lmx4CgA92QBJe4orFdAFAoyWQXD/T.VwYNtTr7VDrdXOQ/SlMS8v32s93PEsl.KOoCRvijHPJx7rd5Q";
            public = false;
            authorization_policy = "one_factor";
            redirect_uris = [ "https://grafana.${cfg.domain}/login/generic_oauth" ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            userinfo_signed_response_alg = "none";
          }
        ];
      };
    };

    systemd.services.authelia-main = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    # Inject Redis password via Authelia's _FILE env var mechanism
    services.authelia.instances.main.environmentVariables = {
      AUTHELIA_SESSION_REDIS_PASSWORD_FILE = config.sops.secrets.authelia_session_redis_password.path;
    };

    networking.firewall.allowedTCPPorts = [ cfg.metricsPort ]; # Authelia metrics
  };
}
