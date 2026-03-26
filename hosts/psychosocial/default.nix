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

  # --- Services ---
  server.disko.enable = true;
  server.caddy.enable = true;
  server.authelia.enable = true;
  server.homepage.enable = true;

  # Caddy routes — all reverse proxy rules for pytt.io
  services.caddy.extraConfig = ''
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

      @home host home.pytt.io
      handle @home {
        import authelia
        reverse_proxy 127.0.0.1:3000
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

      # --- pulse (10.10.30.112) ---

      @ntfy host ntfy.pytt.io
      handle @ntfy {
        # Non-GET requests (POST/PUT publish) and API paths bypass Authelia
        @ntfy_api {
          not method GET HEAD OPTIONS
        }
        handle @ntfy_api {
          reverse_proxy 10.10.30.112:2586
        }
        @ntfy_paths path /v1/* /*.json /*/json /*/sse /*/raw /*/ws /*/auth
        handle @ntfy_paths {
          reverse_proxy 10.10.30.112:2586
        }
        # Web UI (GET) uses Authelia SSO
        handle {
          import authelia
          reverse_proxy 10.10.30.112:2586
        }
      }

      @gatus host gatus.pytt.io
      handle @gatus {
        reverse_proxy 10.10.30.112:8080
      }

      @grafana host grafana.pytt.io
      handle @grafana {
        reverse_proxy 10.10.30.112:3000
      }

      @prometheus host prometheus.pytt.io
      handle @prometheus {
        import authelia
        reverse_proxy 10.10.30.112:9090
      }

      # --- sugar (staging: 10.10.30.111) ---

      @n8n host n8n.pytt.io
      handle @n8n {
        reverse_proxy 10.10.30.111:5678
      }

      @nextcloud host nextcloud.pytt.io
      handle @nextcloud {
        reverse_proxy 10.10.30.111:80
      }

      @mealie host mealie.pytt.io
      handle @mealie {
        reverse_proxy 10.10.30.111:9925
      }

      @norish host norish.pytt.io
      handle @norish {
        reverse_proxy 10.10.30.111:3000
      }

      @wger host wger.pytt.io
      handle @wger {
        # Strip spoofed auth header from all incoming requests
        request_header -Remote-User

        # API paths bypass Authelia — use wger's own token auth
        @wger_api path /api/*
        handle @wger_api {
          reverse_proxy 10.10.30.111:8000
        }
        # Web UI uses Authelia SSO via proxy auth header
        handle {
          import authelia
          reverse_proxy 10.10.30.111:8000
        }
      }

      @searxng host searxng.pytt.io
      handle @searxng {
        reverse_proxy 10.10.30.111:8888
      }

      @perplexica host perplexica.pytt.io
      handle @perplexica {
        reverse_proxy 10.10.30.111:3001
      }

      @freshrss host freshrss.pytt.io
      handle @freshrss {
        # Strip spoofed auth header from all incoming requests
        request_header -Remote-User

        # API paths bypass Authelia — use FreshRSS's own API password auth
        @freshrss_api path /api/*
        handle @freshrss_api {
          reverse_proxy 10.10.30.111:8282
        }
        # Web UI uses Authelia SSO via forward auth
        handle {
          import authelia
          reverse_proxy 10.10.30.111:8282
        }
      }

      @netboot host netboot.pytt.io
      handle @netboot {
        import authelia
        reverse_proxy 10.10.30.111:3003
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

      @openwebui host openwebui.pytt.io
      handle @openwebui {
        reverse_proxy 10.10.10.10:3000
      }

      @ollama host ollama.pytt.io
      handle @ollama {
        reverse_proxy 10.10.10.10:11434
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

      import authelia
      reverse_proxy 127.0.0.1:3000
    }
  '';

  system.stateVersion = "25.05";
}
