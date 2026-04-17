{
  config,
  pkgs,
  lib,
  mkServerNetwork,
  inventory,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    (mkServerNetwork {
      ip = inventory.psychosocial;
      gateway = "10.10.30.1";
    })
  ];

  networking.hostName = "psychosocial";

  # --- Services ---
  server.disko.enable = true;
  server.caddy.enable = true;
  server.homepage.enable = true;
  server.element-web.enable = true;

  # Caddy routes — all reverse proxy rules for pytt.io
  services.caddy.extraConfig = ''
    (authelia) {
      forward_auth auth.pytt.io:443 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        transport http {
          tls
          tls_server_name auth.pytt.io
        }
      }
    }

    *.pytt.io {
      tls {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
        propagation_delay 2m
        resolvers 1.1.1.1
      }

      # --- psychosocial (local) ---

      @home host home.pytt.io
      handle @home {
        import authelia
        reverse_proxy 127.0.0.1:3000
      }

      # --- byob ---

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

      # --- sugar ---

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
        reverse_proxy 10.10.30.111:3100
      }

      @forgejo host forgejo.pytt.io git.pytt.io
      handle @forgejo {
        request_body {
          max_size 1G
        }
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

      @vault host vault.pytt.io
      handle @vault {
        reverse_proxy 10.10.30.111:8222
      }

      @element host element.pytt.io
      handle @element {
        root * ${config.server.element-web.package}
        encode gzip zstd
        try_files {path} /index.html
        file_server
      }

      @matrix host matrix.pytt.io
      handle @matrix {
        handle /.well-known/matrix/client {
          header Content-Type "application/json"
          header Access-Control-Allow-Origin "*"
          respond `{"m.homeserver":{"base_url":"https://matrix.pytt.io"}}`
        }
        handle /.well-known/matrix/server {
          header Content-Type "application/json"
          respond `{"m.server":"matrix.pytt.io:443"}`
        }
        reverse_proxy 10.10.30.111:6167
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
        reverse_proxy https://10.10.10.163:11434 {
          transport http {
            tls_insecure_skip_verify
          }
        }
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

      handle /.well-known/matrix/client {
        header Content-Type "application/json"
        header Access-Control-Allow-Origin "*"
        respond `{"m.homeserver":{"base_url":"https://matrix.pytt.io"}}`
      }

      handle /.well-known/matrix/server {
        header Content-Type "application/json"
        respond `{"m.server":"matrix.pytt.io:443"}`
      }

      import authelia
      reverse_proxy 127.0.0.1:3000
    }
  '';

  # Forward Git SSH (public port 2222) to sugar's host sshd on port 22.
  # Forgejo serves git over SSH via the host sshd using a forced-command in
  # the forgejo user's authorized_keys (not the forgejo built-in SSH server,
  # which is configured but never actually binds). internalInterfaces is set
  # to ens18 so hairpin-NAT'd traffic gets masqueraded — without this, return
  # packets from sugar bypass psychosocial and break the TCP handshake for
  # any client on the same LAN as sugar.
  networking.nat = {
    enable = true;
    externalInterface = "ens18";
    internalInterfaces = [ "ens18" ];
    forwardPorts = [
      {
        destination = "10.10.30.111:22";
        proto = "tcp";
        sourcePort = 2222;
      }
    ];
  };

  system.stateVersion = "25.05";
}
