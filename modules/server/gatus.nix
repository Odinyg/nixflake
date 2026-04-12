{
  config,
  lib,
  ...
}:
let
  cfg = config.server.gatus;
  httpOk = [ "[STATUS] == 200" ];
  httpAny = [ "[STATUS] < 500" ];
in
{
  options.server.gatus = {
    enable = lib.mkEnableOption "Gatus uptime monitoring";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for the Gatus web interface";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for Gatus";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.gatus_oidc_client_secret = { };

    sops.templates."gatus-env".content = ''
      GATUS_OIDC_CLIENT_SECRET=${config.sops.placeholder.gatus_oidc_client_secret}
      DOMAIN=${cfg.domain}
    '';

    systemd.services.gatus = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    services.gatus = {
      enable = true;
      openFirewall = true;
      environmentFile = config.sops.templates."gatus-env".path;
      settings = {
        web.port = cfg.port;

        security.oidc = {
          issuer-url = "https://auth.${cfg.domain}";
          redirect-url = "https://gatus.${cfg.domain}/authorization-code/callback";
          client-id = "gatus";
          client-secret = "\${GATUS_OIDC_CLIENT_SECRET}";
          scopes = [
            "openid"
            "profile"
            "email"
          ];
        };

        endpoints = [
          # --- Reverse Proxy (psychosocial) ---
          {
            name = "Authelia";
            group = "Infrastructure";
            url = "https://auth.${cfg.domain}";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Homepage";
            group = "Infrastructure";
            url = "https://home.${cfg.domain}";
            interval = "5m";
            conditions = httpAny;
          }

          # --- Media (byob: 10.10.50.110) ---
          {
            name = "Sonarr";
            group = "ARR";
            url = "http://10.10.50.110:8989";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Radarr";
            group = "ARR";
            url = "http://10.10.50.110:7878";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Lidarr";
            group = "ARR";
            url = "http://10.10.50.110:8686";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Prowlarr";
            group = "ARR";
            url = "http://10.10.50.110:9696";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "NZBGet";
            group = "Downloads";
            url = "http://10.10.50.110:6789";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Transmission";
            group = "Downloads";
            url = "http://10.10.50.110:9091/transmission/web/";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Jellyseerr";
            group = "Media";
            url = "http://10.10.50.110:5055";
            interval = "5m";
            conditions = httpOk;
          }

          # --- Monitoring (pulse: local) ---
          {
            name = "Grafana";
            group = "Monitoring";
            url = "http://127.0.0.1:3000/api/health";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Prometheus";
            group = "Monitoring";
            url = "http://127.0.0.1:9090/-/healthy";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Loki";
            group = "Monitoring";
            url = "http://127.0.0.1:3100/ready";
            interval = "5m";
            conditions = httpOk;
          }

          # --- Apps (sugar: 10.10.30.111) ---
          {
            name = "Nextcloud";
            group = "Apps";
            url = "http://10.10.30.111:80";
            interval = "5m";
            conditions = httpAny;
          }
          {
            name = "n8n";
            group = "Apps";
            url = "http://10.10.30.111:5678";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "SearXNG";
            group = "Apps";
            url = "http://10.10.30.111:8888";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Norish";
            group = "Apps";
            url = "http://10.10.30.111:3000";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Perplexica";
            group = "Apps";
            url = "http://10.10.30.111:3001";
            interval = "5m";
            conditions = httpOk;
          }

          # --- TrueNAS / Media ---
          {
            name = "Jellyfin";
            group = "Media";
            url = "http://10.10.10.20:30013";
            interval = "5m";
            conditions = httpOk;
          }

          # --- Infrastructure ---
          {
            name = "Proxmox 1";
            group = "Infrastructure";
            url = "https://10.10.10.227:8006";
            interval = "5m";
            client.insecure = true;
            conditions = httpOk;
          }
          {
            name = "Proxmox 2";
            group = "Infrastructure";
            url = "https://10.10.10.228:8006";
            interval = "5m";
            client.insecure = true;
            conditions = httpOk;
          }
          {
            name = "TrueNAS";
            group = "Infrastructure";
            url = "https://10.10.10.20";
            interval = "5m";
            client.insecure = true;
            conditions = httpOk;
          }

          # --- Other ---
          {
            name = "Home Assistant";
            group = "Home";
            url = "http://10.10.20.205:8123";
            interval = "5m";
            conditions = httpOk;
          }
          {
            name = "Ollama";
            group = "Apps";
            url = "http://10.10.10.163:11434";
            interval = "5m";
            conditions = httpOk;
          }
        ];
      };
    };
  };
}
