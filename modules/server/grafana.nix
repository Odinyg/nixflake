{
  config,
  lib,
  ...
}:
let
  cfg = config.server.grafana;
in
{
  options.server.grafana = {
    enable = lib.mkEnableOption "Grafana dashboards";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for the Grafana web interface";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for Grafana";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.grafana_admin_password = {
      owner = "grafana";
    };
    sops.secrets.grafana_oauth_client_id = {
      owner = "grafana";
    };
    sops.secrets.grafana_oauth_client_secret = {
      owner = "grafana";
    };
    sops.secrets.grafana_secret_key = {
      owner = "grafana";
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = cfg.port;
          root_url = "https://grafana.${cfg.domain}";
        };
        security.secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
        analytics.reporting_enabled = false;

        "auth.generic_oauth" = {
          enabled = true;
          name = "Authelia";
          client_id = "$__file{${config.sops.secrets.grafana_oauth_client_id.path}}";
          client_secret = "$__file{${config.sops.secrets.grafana_oauth_client_secret.path}}";
          scopes = "openid profile email groups";
          auth_url = "https://auth.${cfg.domain}/api/oidc/authorization";
          token_url = "https://auth.${cfg.domain}/api/oidc/token";
          api_url = "https://auth.${cfg.domain}/api/oidc/userinfo";
          login_attribute_path = "preferred_username";
          name_attribute_path = "name";
          email_attribute_path = "email";
          use_refresh_token = true;
          allow_sign_up = true;
          role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";
        };
      };

      provision = {
        datasources.settings = {
          apiVersion = 1;
          deleteDatasources = [
            { name = "Prometheus"; orgId = 1; }
            { name = "Loki"; orgId = 1; }
          ];
          datasources = [
            {
              name = "Prometheus";
              uid = "prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:9090";
              isDefault = true;
              orgId = 1;
            }
            {
              name = "Loki";
              uid = "loki";
              type = "loki";
              url = "http://127.0.0.1:3100";
              orgId = 1;
            }
          ];
        };
        dashboards.settings.providers = [
          {
            name = "default";
            options.path = "/etc/grafana/dashboards";
          }
        ];
      };
    };

    systemd.services.grafana = {
      serviceConfig.EnvironmentFile = config.sops.templates."grafana-env".path;
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    sops.templates."grafana-env".content = ''
      GF_SECURITY_ADMIN_PASSWORD=${config.sops.placeholder.grafana_admin_password}
    '';
    environment.etc = {
      "grafana/dashboards/node-exporter.json".source = ./dashboards/node-exporter.json;
      "grafana/dashboards/caddy.json".source = ./dashboards/caddy.json;
      "grafana/dashboards/loki-logs.json".source = ./dashboards/loki-logs.json;
      "grafana/dashboards/homelab-services.json".source = ./dashboards/homelab-services.json;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
