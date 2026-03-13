{
  config,
  pkgs-unstable,
  inputs,
  lib,
  ...
}:
let
  cfg = config.server.homepage;
in
{
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/homepage-dashboard.nix"
  ];

  # Use unstable homepage-dashboard module (for environmentFiles support)
  disabledModules = [ "services/misc/homepage-dashboard.nix" ];

  options.server.homepage = {
    enable = lib.mkEnableOption "Homepage dashboard";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for the Homepage dashboard";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        homepage-dashboard = pkgs-unstable.homepage-dashboard;
      })
    ];

    sops.secrets.homepage_jellyfin_api_key = { };
    sops.secrets.homepage_jellyseerr_api_key = { };
    sops.secrets.homepage_sonarr_api_key = { };
    sops.secrets.homepage_radarr_api_key = { };
    sops.secrets.homepage_lidarr_api_key = { };
    sops.secrets.homepage_prowlarr_api_key = { };
    sops.secrets.homepage_homeassistant_api_key = { };
    sops.secrets.homepage_proxmox_token_id = { };
    sops.secrets.homepage_proxmox_token_secret = { };
    sops.secrets.homepage_truenas_api_key = { };
    sops.secrets.homepage_nzbget_user = { };
    sops.secrets.homepage_nzbget_pass = { };
    sops.secrets.homepage_transmission_user = { };
    sops.secrets.homepage_transmission_pass = { };

    sops.templates."homepage-env".content = ''
      HOMEPAGE_VAR_JELLYFIN_API_KEY=${config.sops.placeholder.homepage_jellyfin_api_key}
      HOMEPAGE_VAR_JELLYSEERR_API_KEY=${config.sops.placeholder.homepage_jellyseerr_api_key}
      HOMEPAGE_VAR_SONARR_API_KEY=${config.sops.placeholder.homepage_sonarr_api_key}
      HOMEPAGE_VAR_RADARR_API_KEY=${config.sops.placeholder.homepage_radarr_api_key}
      HOMEPAGE_VAR_LIDARR_API_KEY=${config.sops.placeholder.homepage_lidarr_api_key}
      HOMEPAGE_VAR_PROWLARR_API_KEY=${config.sops.placeholder.homepage_prowlarr_api_key}
      HOMEPAGE_VAR_HOMEASSISTANT_API_KEY=${config.sops.placeholder.homepage_homeassistant_api_key}
      HOMEPAGE_VAR_PROXMOX_TOKEN_ID=${config.sops.placeholder.homepage_proxmox_token_id}
      HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET=${config.sops.placeholder.homepage_proxmox_token_secret}
      HOMEPAGE_VAR_TRUENAS_API_KEY=${config.sops.placeholder.homepage_truenas_api_key}
      HOMEPAGE_VAR_NZBGET_USER=${config.sops.placeholder.homepage_nzbget_user}
      HOMEPAGE_VAR_NZBGET_PASS=${config.sops.placeholder.homepage_nzbget_pass}
      HOMEPAGE_VAR_TRANSMISSION_USER=${config.sops.placeholder.homepage_transmission_user}
      HOMEPAGE_VAR_TRANSMISSION_PASS=${config.sops.placeholder.homepage_transmission_pass}
    '';

    systemd.services.homepage-dashboard = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;
      allowedHosts = "${cfg.domain},home.${cfg.domain}";
      environmentFiles = [ config.sops.templates."homepage-env".path ];

      settings = {
        title = cfg.domain;
        theme = "dark";
        color = "slate";
        headerStyle = "clean";
        layout = {
          Main = {
            style = "row";
            columns = 4;
          };
          Infrastructure = {
            style = "row";
            columns = 3;
          };
          Monitoring = {
            style = "row";
            columns = 4;
          };
          Media = {
            style = "row";
            columns = 2;
          };
          ARRrr = {
            style = "row";
            columns = 4;
          };
          Tools = {
            style = "row";
            columns = 4;
          };
        };
      };

      widgets = [
        {
          search = {
            provider = "custom";
            url = "https://searxng.${cfg.domain}/search?q=";
            suggestionUrl = "https://searxng.${cfg.domain}/autocompleter?q=";
            focus = true;
            showSearchSuggestions = true;
            target = "_blank";
          };
        }
      ];

      proxmox = {
        pve = {
          url = "https://10.10.10.227:8006";
          token = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_ID}}";
          secret = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET}}";
        };
        pve2 = {
          url = "https://10.10.10.228:8006";
          token = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_ID}}";
          secret = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET}}";
        };
      };

      services = [
        {
          Main = [
            {
              "Home Assistant" = {
                icon = "home-assistant.png";
                href = "https://homeassistant.${cfg.domain}";
                description = "Home Automation";
                siteMonitor = "http://10.10.20.205:8123";
                widget = {
                  type = "homeassistant";
                  url = "http://10.10.20.205:8123";
                  key = "{{HOMEPAGE_VAR_HOMEASSISTANT_API_KEY}}";
                };
              };
            }
            {
              Nextcloud = {
                icon = "nextcloud.png";
                href = "https://nextcloud.${cfg.domain}";
                description = "File Storage & Collaboration";
                siteMonitor = "http://10.10.30.111:80";
              };
            }
            {
              Norish = {
                icon = "norish.png";
                href = "https://norish.${cfg.domain}";
                description = "Bookmarks & Read Later";
                siteMonitor = "http://10.10.30.111:3000";
              };
            }
            {
              Perplexica = {
                icon = "perplexica.png";
                href = "https://perplexica.${cfg.domain}";
                description = "AI Search Engine";
                siteMonitor = "http://10.10.30.111:3001";
              };
            }
          ];
        }
        {
          Infrastructure = [
            {
              "Proxmox 1" = {
                icon = "proxmox.png";
                href = "https://pve1.${cfg.domain}";
                description = "Hypervisor";
                siteMonitor = "https://10.10.10.227:8006";
                widget = {
                  type = "proxmox";
                  url = "https://10.10.10.227:8006";
                  username = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_ID}}";
                  password = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET}}";
                  node = "pve";
                };
              };
            }
            {
              "Proxmox 2" = {
                icon = "proxmox.png";
                href = "https://pve2.${cfg.domain}";
                description = "Hypervisor";
                siteMonitor = "https://10.10.10.228:8006";
                widget = {
                  type = "proxmox";
                  url = "https://10.10.10.228:8006";
                  username = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_ID}}";
                  password = "{{HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET}}";
                  node = "pve2";
                };
              };
            }
            {
              TrueNAS = {
                icon = "truenas.png";
                href = "https://truenas.${cfg.domain}";
                description = "Storage Server";
                siteMonitor = "https://10.10.10.20";
                widget = {
                  type = "truenas";
                  url = "https://10.10.10.20";
                  key = "{{HOMEPAGE_VAR_TRUENAS_API_KEY}}";
                  enablePools = true;
                };
              };
            }
          ];
        }
        {
          Monitoring = [
            {
              Gatus = {
                icon = "gatus.png";
                href = "https://gatus.${cfg.domain}";
                description = "Declarative Monitoring";
                siteMonitor = "http://10.10.30.12:8080";
              };
            }
            {
              Grafana = {
                icon = "grafana.png";
                href = "https://grafana.${cfg.domain}";
                description = "Dashboards & Logs";
                siteMonitor = "http://10.10.30.12:3000/api/health";
              };
            }
          ];
        }
        {
          Media = [
            {
              Jellyfin = {
                icon = "jellyfin.png";
                href = "https://jellyfin.${cfg.domain}";
                description = "Media Player";
                siteMonitor = "http://10.10.10.20:30013";
                widget = {
                  type = "jellyfin";
                  url = "http://10.10.10.20:30013";
                  key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
                  enableBlocks = true;
                  enableNowPlaying = true;
                };
              };
            }
            {
              Jellyseerr = {
                icon = "jellyseerr.png";
                href = "https://jellyseerr.${cfg.domain}";
                description = "Media Requests";
                siteMonitor = "http://10.10.50.110:5055";
                widget = {
                  type = "jellyseerr";
                  url = "http://10.10.50.110:5055";
                  key = "{{HOMEPAGE_VAR_JELLYSEERR_API_KEY}}";
                };
              };
            }
          ];
        }
        {
          ARRrr = [
            {
              Radarr = {
                icon = "radarr.png";
                href = "https://radarr.${cfg.domain}";
                description = "Movie Management";
                siteMonitor = "http://10.10.50.110:7878";
                widget = {
                  type = "radarr";
                  url = "http://10.10.50.110:7878";
                  key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
                };
              };
            }
            {
              Sonarr = {
                icon = "sonarr.png";
                href = "https://sonarr.${cfg.domain}";
                description = "TV Shows";
                siteMonitor = "http://10.10.50.110:8989";
                widget = {
                  type = "sonarr";
                  url = "http://10.10.50.110:8989";
                  key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
                };
              };
            }
            {
              Lidarr = {
                icon = "lidarr.png";
                href = "https://lidarr.${cfg.domain}";
                description = "Music Management";
                siteMonitor = "http://10.10.50.110:8686";
                widget = {
                  type = "lidarr";
                  url = "http://10.10.50.110:8686";
                  key = "{{HOMEPAGE_VAR_LIDARR_API_KEY}}";
                };
              };
            }
            {
              Prowlarr = {
                icon = "prowlarr.png";
                href = "https://prowlarr.${cfg.domain}";
                description = "Indexer Manager";
                siteMonitor = "http://10.10.50.110:9696";
                widget = {
                  type = "prowlarr";
                  url = "http://10.10.50.110:9696";
                  key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
                };
              };
            }
            {
              Transmission = {
                icon = "transmission.png";
                href = "https://transmission.${cfg.domain}";
                description = "Torrent Client";
                widget = {
                  type = "transmission";
                  url = "http://10.10.50.110:9091";
                  username = "{{HOMEPAGE_VAR_TRANSMISSION_USER}}";
                  password = "{{HOMEPAGE_VAR_TRANSMISSION_PASS}}";
                };
              };
            }
            {
              NZBGet = {
                icon = "nzbget.png";
                href = "https://nzbget.${cfg.domain}";
                description = "Usenet Downloader";
                widget = {
                  type = "nzbget";
                  url = "http://10.10.50.110:6789";
                  username = "{{HOMEPAGE_VAR_NZBGET_USER}}";
                  password = "{{HOMEPAGE_VAR_NZBGET_PASS}}";
                };
              };
            }
          ];
        }
        {
          Tools = [
            {
              SearXNG = {
                icon = "searxng.png";
                href = "https://searxng.${cfg.domain}";
                description = "Privacy Search Engine";
                siteMonitor = "http://10.10.30.111:8888";
              };
            }
            {
              n8n = {
                icon = "n8n.png";
                href = "https://n8n.${cfg.domain}";
                description = "Workflow Automation";
                siteMonitor = "http://10.10.30.111:5678";
              };
            }
            {
              Ollama = {
                icon = "ollama.png";
                href = "https://ollama.${cfg.domain}";
                description = "LLM Server";
                siteMonitor = "http://192.168.1.91:11434";
              };
            }
          ];
        }
      ];
    };
  };
}
