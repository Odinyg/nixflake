{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "psychosocial";

  # Static IP — staging (change to 10.10.30.10 after cutover)
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.30.110";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.10.30.1";
    nameservers = [
      "10.10.30.1"
      "1.1.1.1"
    ];
  };

  sops.defaultSopsFile = ../../secrets/psychosocial.yaml;

  # --- Caddy secrets ---
  sops.secrets.caddy_cloudflare_api_token = { };
  sops.templates."caddy-env".content = ''
    CLOUDFLARE_API_TOKEN=${config.sops.placeholder.caddy_cloudflare_api_token}
  '';

  # --- Authelia secrets ---
  sops.secrets.authelia_jwt_secret = { owner = "authelia-main"; };
  sops.secrets.authelia_session_secret = { owner = "authelia-main"; };
  sops.secrets.authelia_storage_encryption_key = { owner = "authelia-main"; };
  sops.secrets.authelia_oidc_hmac_secret = { owner = "authelia-main"; };
  sops.secrets.authelia_session_redis_password = { owner = "authelia-main"; };

  # --- Authelia users database (hashed passwords — safe in store) ---
  environment.etc."authelia/users_database.yml" = {
    text = ''
      ---
      users:
        homelab:
          disabled: false
          displayname: Homelab Admin
          email: admin@pytt.io
          password: '$argon2id$v=19$m=65536,t=3,p=4$g/+SvP06elXQTV8r2OeDcQ$l64+8ouJBTYlKjVWHqUqXPwEaLq7U3/pFjG27vC0EKU'
          groups:
            - admins
    '';
    mode = "0440";
    user = "authelia-main";
    group = "authelia-main";
  };

  # --- Authelia ---
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
      server.address = "tcp://127.0.0.1:9091";

      telemetry.metrics = {
        enabled = true;
        address = "tcp://0.0.0.0:9959";
      };

      log.level = "info";

      webauthn = {
        enable_passkey_login = true;
        display_name = "pytt.io";
        attestation_conveyance_preference = "indirect";
        timeout = "60s";
        selection_criteria.user_verification = "preferred";
      };

      totp.issuer = "pytt.io";

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
            domain = "pytt.io";
            authelia_url = "https://auth.pytt.io";
            default_redirection_url = "https://home.pytt.io";
          }
        ];
        redis = {
          host = "10.10.10.20";
          port = 30059;
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
          { domain = "auth.pytt.io"; policy = "bypass"; }
          {
            domain = [ "pve1.pytt.io" "truenas.pytt.io" ];
            policy = "one_factor";
            subject = [ "group:admins" ];
          }
          {
            domain = [ "pve2.pytt.io" ];
            policy = "two_factor";
            subject = [ "group:admins" ];
          }
          { domain = [ "*.pytt.io" ]; policy = "one_factor"; }
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
          redirect_uris = [ "https://pve1.pytt.io" "https://pve2.pytt.io" ];
          scopes = [ "openid" "profile" "email" ];
          userinfo_signed_response_alg = "none";
        }
        {
          client_id = "norish";
          client_name = "Norish";
          client_secret = "$pbkdf2-sha512$310000$QQL4jfrdXFc6SWtDGut/.w$qsH/9g/YkpMK73A6aLf80x26Vl3VJEZqN/Wwd6HnJ1M6DJf1T4PZloHVibF5tj7iQdxWzhEEe5oaj86qjL.meQ";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [ "https://norish.pytt.io/api/auth/oauth2/callback/oidc" ];
          scopes = [ "openid" "profile" "email" ];
          userinfo_signed_response_alg = "none";
        }
        {
          client_id = "gatus";
          client_name = "Gatus";
          client_secret = "$pbkdf2-sha512$310000$4ER2edlklu3DXb01L4x/rw$svXMXo1NHy8hDyh62DH3YPA1YKI4mU6ilL6/esaStHfk55IqYs5Cx4xVGzu8nq1VQFYSbrReysTzQgod1Uk9tQ";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [ "https://gatus.pytt.io/authorization-code/callback" ];
          scopes = [ "openid" "profile" "email" ];
          userinfo_signed_response_alg = "none";
        }
        {
          client_id = "grafana";
          client_name = "Grafana";
          client_secret = "$pbkdf2-sha512$310000$K2HozYqmNUwBDwq2YG86eQ$Z7ZEuA7Lmx4CgA92QBJe4orFdAFAoyWQXD/T.VwYNtTr7VDrdXOQ/SlMS8v32s93PEsl.KOoCRvijHPJx7rd5Q";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [ "https://grafana.pytt.io/login/generic_oauth" ];
          scopes = [ "openid" "profile" "email" "groups" ];
          userinfo_signed_response_alg = "none";
        }
      ];
    };
  };

  # Inject Redis password via Authelia's _FILE env var mechanism
  services.authelia.instances.main.environmentVariables = {
    AUTHELIA_SESSION_REDIS_PASSWORD_FILE = config.sops.secrets.authelia_session_redis_password.path;
  };

  # --- Caddy ---
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
      hash = "sha256-48Xq2tb8ruAl87IJNWlIQa6bLISmNic0LuMNAJO7/n0=";
    };
    globalConfig = ''
      admin 0.0.0.0:2019
      servers {
        metrics
      }
    '';
    extraConfig = ''
      (authelia) {
        forward_auth 127.0.0.1:9091 {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
      }

      *.pytt.io {
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
          propagation_delay 2m
          resolvers 1.1.1.1
        }

        # --- psychosocial (local) ---

        @auth host auth.pytt.io
        handle @auth {
          reverse_proxy 127.0.0.1:9091
        }

        # --- byob (staging: 10.10.50.110) ---

        @sonarr host sonarr.pytt.io
        handle @sonarr {
          reverse_proxy 10.10.50.110:8989
        }

        @radarr host radarr.pytt.io
        handle @radarr {
          reverse_proxy 10.10.50.110:7878
        }

        @lidarr host lidarr.pytt.io
        handle @lidarr {
          reverse_proxy 10.10.50.110:8686
        }

        @prowlarr host prowlarr.pytt.io
        handle @prowlarr {
          reverse_proxy 10.10.50.110:9696
        }

        @nzbget host nzbget.pytt.io
        handle @nzbget {
          reverse_proxy 10.10.50.110:6789
        }

        @transmission host transmission.pytt.io
        handle @transmission {
          reverse_proxy 10.10.50.110:9091
        }

        @jellyseerr host jellyseerr.pytt.io
        handle @jellyseerr {
          reverse_proxy 10.10.50.110:5055
        }

        @huntarr host huntarr.pytt.io
        handle @huntarr {
          reverse_proxy 10.10.50.110:9705
        }

        # --- pulse (old: 10.10.30.12) ---

        @gatus host gatus.pytt.io
        handle @gatus {
          reverse_proxy 10.10.30.12:8080
        }

        @grafana host grafana.pytt.io
        handle @grafana {
          reverse_proxy 10.10.30.12:3000
        }

        @prometheus host prometheus.pytt.io
        handle @prometheus {
          import authelia
          reverse_proxy 10.10.30.12:9090
        }

        # --- sugar (old: 10.10.30.11) ---

        @n8n host n8n.pytt.io
        handle @n8n {
          reverse_proxy 10.10.30.11:5678
        }

        @nextcloud host nextcloud.pytt.io
        handle @nextcloud {
          reverse_proxy 10.10.30.11:8080
        }

        @norish host norish.pytt.io
        handle @norish {
          reverse_proxy 10.10.30.11:3000
        }

        @myrlin host myrlin.pytt.io
        handle @myrlin {
          reverse_proxy 10.10.30.11:3456
        }

        @paseo host paseo.pytt.io
        handle @paseo {
          reverse_proxy 10.10.30.11:6767
        }

        @searxng host searxng.pytt.io
        handle @searxng {
          import authelia
          reverse_proxy 10.10.30.11:8888
        }

        @perplexica host perplexica.pytt.io
        handle @perplexica {
          import authelia
          reverse_proxy 10.10.30.11:3001
        }

        @sparkyfitness host sparkyfitness.pytt.io
        handle @sparkyfitness {
          reverse_proxy 10.10.30.11:3004
        }

        @netboot host netboot.pytt.io
        handle @netboot {
          import authelia
          reverse_proxy 10.10.30.11:3003
        }

        # --- TrueNAS / Kubernetes ---

        @jellyfin host jellyfin.pytt.io
        handle @jellyfin {
          reverse_proxy 10.10.10.20:30013
        }

        # --- Infrastructure ---

        @pve1 host pve1.pytt.io
        handle @pve1 {
          reverse_proxy https://10.10.10.227:8006 {
            transport http {
              tls
              tls_insecure_skip_verify
            }
          }
        }

        @pve2 host pve2.pytt.io
        handle @pve2 {
          reverse_proxy https://10.10.10.228:8006 {
            transport http {
              tls
              tls_insecure_skip_verify
            }
          }
        }

        @truenas host truenas.pytt.io
        handle @truenas {
          reverse_proxy https://10.10.10.20 {
            transport http {
              tls
              tls_insecure_skip_verify
            }
          }
        }

        # --- Other ---

        @craftbeerpi host craftbeerpi.pytt.io
        handle @craftbeerpi {
          reverse_proxy 10.10.20.174:8000
        }

        @homeassistant host homeassistant.pytt.io
        handle @homeassistant {
          reverse_proxy 10.10.20.205:8123
        }

        @ollama host ollama.pytt.io
        handle @ollama {
          reverse_proxy 192.168.1.91:11434
        }

        handle {
          respond "Not found" 404
        }
      }

      pytt.io {
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
          propagation_delay 2m
          resolvers 1.1.1.1
        }

        respond "Coming soon" 200
      }
    '';
  };

  # Inject Cloudflare API token into Caddy
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."caddy-env".path;

  networking.firewall.allowedTCPPorts = [
    80 # Caddy HTTP (ACME + redirect)
    443 # Caddy HTTPS
    9959 # Authelia metrics
  ];

  system.stateVersion = "25.05";
}
