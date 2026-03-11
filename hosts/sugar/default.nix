{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.config.permittedInsecurePackages = [
    "n8n-1.91.3"
  ];

  networking.hostName = "sugar";

  # Static IP — staging (change to 10.10.30.11 after cutover)
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.30.111";
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

  sops.defaultSopsFile = ../../secrets/sugar.yaml;

  # --- SOPS secrets ---

  # n8n
  sops.secrets.n8n_db_password = { };

  # SearXNG
  sops.secrets.searxng_secret = { };

  # Nextcloud
  sops.secrets.nextcloud_admin_pass = { owner = "nextcloud"; };
  sops.secrets.nextcloud_db_pass = { owner = "nextcloud"; };

  # Shared Redis password
  sops.secrets.redis_pass = { };

  # Norish
  sops.secrets.norish_db_pass = { };
  sops.secrets.norish_master_key = { };
  sops.secrets.norish_oidc_client_secret = { };


  # --- Firewall ---
  networking.firewall = {
    allowedTCPPorts = [
      80      # Nextcloud (nginx managed by module)
      3000    # Norish
      3001    # Perplexica
      3003    # netboot.xyz web UI

      5678    # n8n

      8086    # netboot.xyz assets
      8888    # SearXNG
    ];
    allowedUDPPorts = [
      69      # netboot.xyz TFTP
    ];
  };

  # --- SOPS environment file templates ---

  sops.templates."n8n-env".content = ''
    DB_TYPE=postgresdb
    DB_POSTGRESDB_HOST=10.10.10.20
    DB_POSTGRESDB_PORT=5432
    DB_POSTGRESDB_DATABASE=n8n
    DB_POSTGRESDB_USER=n8n
    DB_POSTGRESDB_PASSWORD=${config.sops.placeholder.n8n_db_password}
    N8N_SECURE_COOKIE=false
    N8N_METRICS=true
    GENERIC_TIMEZONE=Europe/Oslo
  '';

  sops.templates."searxng-env".content = ''
    SEARXNG_SECRET=${config.sops.placeholder.searxng_secret}
  '';

  # Nextcloud secret file — JSON format for secretFile option
  sops.templates."nextcloud-secret".content = ''
    {"redis":{"password":"${config.sops.placeholder.redis_pass}"}}
  '';

  sops.templates."norish-env".content = ''
    AUTH_URL=https://norish.pytt.io
    DATABASE_URL=postgres://norish:${config.sops.placeholder.norish_db_pass}@10.10.10.20:5432/norish
    MASTER_KEY=${config.sops.placeholder.norish_master_key}
    REDIS_URL=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:6380
    OIDC_NAME=Authelia
    OIDC_ISSUER=https://auth.pytt.io
    OIDC_CLIENT_ID=norish
    OIDC_CLIENT_SECRET=${config.sops.placeholder.norish_oidc_client_secret}
    TRUSTED_ORIGINS=https://norish.pytt.io
  '';


  # --- Native Services ---

  # n8n — workflow automation
  services.n8n = {
    enable = true;
    openFirewall = false; # managed manually above
  };
  systemd.services.n8n.serviceConfig.EnvironmentFile =
    config.sops.templates."n8n-env".path;

  # SearXNG — privacy search engine
  services.searx = {
    enable = true;
    package = pkgs.searxng;
    redisCreateLocally = true;
    environmentFile = config.sops.templates."searxng-env".path;
    settings = {
      server = {
        port = 8888;
        bind_address = "0.0.0.0";
        secret_key = "$SEARXNG_SECRET";
      };
      search = {
        safe_search = 0;
        autocomplete = "google";
      };
      ui = {
        default_locale = "en";
        query_in_title = true;
      };
    };
  };

  # Nextcloud — file storage and collaboration
  # Redis for Nextcloud caching
  services.redis.servers.nextcloud = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
    requirePassFile = config.sops.secrets.redis_pass.path;
  };

  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.pytt.io";
    package = pkgs.nextcloud32;
    maxUploadSize = "1G";

    config = {
      adminuser = "none";
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
      dbtype = "pgsql";
      dbhost = "10.10.10.20:5432";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      dbpassFile = config.sops.secrets.nextcloud_db_pass.path;
    };

    settings = {
      overwriteprotocol = "https";
      trusted_proxies = [ "10.10.30.110" ];  # psychosocial (staging)
      default_phone_region = "NO";
      log_type = "systemd";
    };

    # Secret file injects Redis password into config.php at runtime
    secretFile = config.sops.templates."nextcloud-secret".path;

    caching.redis = true;
  };

  # Wire Nextcloud to local Redis
  systemd.services.nextcloud-setup = {
    after = [ "redis-nextcloud.service" ];
    requires = [ "redis-nextcloud.service" ];
  };

  # --- OCI Containers (no NixOS module) ---

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  virtualisation.oci-containers.backend = "docker";

  # Create docker network for inter-container communication
  systemd.services.create-sugar-network = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    script = ''
      ${pkgs.docker}/bin/docker network inspect iowa >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create iowa
    '';
  };

  virtualisation.oci-containers.containers = {

    # Perplexica — AI-powered search engine (slim = uses external SearXNG)
    perplexica = {
      image = "itzcrazykns1337/perplexica:slim-latest";
      environment = {
        SEARXNG_API_URL = "http://127.0.0.1:8888";
      };
      volumes = [
        "/var/lib/homelab/perplexica/data:/home/perplexica/data"
        "/var/lib/homelab/perplexica/uploads:/home/perplexica/uploads"
      ];
      ports = [ "3001:3000" ];
      extraOptions = [ "--network=iowa" ];
    };

    # netboot.xyz — PXE boot server (official image, LinuxServer deprecated)
    netbootxyz = {
      image = "ghcr.io/netbootxyz/netbootxyz";
      volumes = [
        "/var/lib/homelab/netbootxyz/config:/config"
        "/var/lib/homelab/netbootxyz/assets:/assets"
      ];
      ports = [
        "3003:3000"   # web UI
        "69:69/udp"   # TFTP
        "8086:8080"   # assets HTTP server
      ];
      extraOptions = [ "--network=iowa" ];
    };

    # Norish — recipe app with OIDC
    norish = {
      image = "norishapp/norish:latest";
      environmentFiles = [ config.sops.templates."norish-env".path ];
      volumes = [
        "/var/lib/homelab/norish/uploads:/app/uploads"
      ];
      ports = [ "3000:3000" ];
      extraOptions = [ "--network=iowa" ];
    };

  };

  # Norish also needs Redis — separate named instance on port 6380
  services.redis.servers.norish = {
    enable = true;
    port = 6380;
    bind = "127.0.0.1";
    requirePassFile = config.sops.secrets.redis_pass.path;
  };

  # Persistent data directories
  systemd.tmpfiles.rules = [
    "d /var/lib/homelab 0755 root root -"
    "d /var/lib/homelab/perplexica 0755 root root -"
    "d /var/lib/homelab/perplexica/data 0755 root root -"
    "d /var/lib/homelab/perplexica/uploads 0755 root root -"
    "d /var/lib/homelab/netbootxyz 0755 root root -"
    "d /var/lib/homelab/netbootxyz/config 0755 root root -"
    "d /var/lib/homelab/netbootxyz/assets 0755 root root -"
    "d /var/lib/homelab/norish 0755 root root -"
    "d /var/lib/homelab/norish/uploads 0755 root root -"
  ];

  system.stateVersion = "25.05";
}
