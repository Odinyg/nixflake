{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "pulse";

  sops.defaultSopsFile = ../../secrets/pulse.yaml;

  sops.secrets.grafana_admin_password = {
    owner = "grafana";
  };
  sops.secrets.grafana_oauth_client_id = {
    owner = "grafana";
  };
  sops.secrets.grafana_oauth_client_secret = {
    owner = "grafana";
  };
  sops.secrets.gatus_oidc_client_secret = { };

  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    3100 # Loki
    8080 # Gatus
    9090 # Prometheus
  ];

  # --- Prometheus ---
  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "30d";
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "10.10.30.110:9100" # psychosocial (staging)
              "10.10.50.110:9100" # byob (staging)
              "10.10.30.111:9100" # sugar (staging)
              "127.0.0.1:9100" # pulse (local)
            ];
          }
        ];
      }
      {
        job_name = "caddy";
        static_configs = [
          { targets = [ "10.10.30.110:2019" ]; }
        ];
      }
      {
        job_name = "authelia";
        static_configs = [
          { targets = [ "10.10.30.110:9959" ]; }
        ];
      }
    ];
  };

  # --- Loki ---
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      auth_enabled = false;

      common = {
        path_prefix = "/var/lib/loki";
        ring.kvstore.store = "inmemory";
        replication_factor = 1;
      };

      schema_config.configs = [
        {
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      storage_config.filesystem.directory = "/var/lib/loki/chunks";

      query_range.results_cache.cache.embedded_cache = {
        enabled = true;
        max_size_mb = 100;
      };

      limits_config = {
        retention_period = "30d";
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        delete_request_store = "filesystem";
        retention_enabled = true;
      };
    };
  };

  # --- Grafana ---
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        root_url = "https://grafana.pytt.io";
      };
      analytics.reporting_enabled = false;

      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        client_id = "$__file{${config.sops.secrets.grafana_oauth_client_id.path}}";
        client_secret = "$__file{${config.sops.secrets.grafana_oauth_client_secret.path}}";
        scopes = "openid profile email groups";
        auth_url = "https://auth.pytt.io/api/oidc/authorization";
        token_url = "https://auth.pytt.io/api/oidc/token";
        api_url = "https://auth.pytt.io/api/oidc/userinfo";
        login_attribute_path = "preferred_username";
        name_attribute_path = "name";
        email_attribute_path = "email";
        use_refresh_token = true;
        allow_sign_up = true;
        role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";
      };
    };

    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://127.0.0.1:3100";
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = "/etc/grafana/dashboards";
          options.foldersFromFilesStructure = true;
        }
      ];
    };
  };

  # Grafana admin password from SOPS
  sops.templates."grafana-env".content = ''
    GF_SECURITY_ADMIN_PASSWORD=${config.sops.placeholder.grafana_admin_password}
  '';
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.sops.templates."grafana-env".path;

  # --- Gatus ---
  services.gatus = {
    enable = true;
    openFirewall = true;
    environmentFile = config.sops.templates."gatus-env".path;
    settings = {
      web.port = 8080;
    };
  };

  sops.templates."gatus-env".content = ''
    GATUS_OIDC_CLIENT_SECRET=${config.sops.placeholder.gatus_oidc_client_secret}
    DOMAIN=pytt.io
  '';

  system.stateVersion = "25.05";
}
