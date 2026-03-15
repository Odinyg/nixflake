# Sugar — Full Host Migration Plan

**Status:** plan-complete
**Host:** sugar (staging IP: 10.10.30.111, production IP: 10.10.30.11)
**Date:** 2026-03-08
**Services:** n8n, SearXNG, Nextcloud, Perplexica, netboot.xyz, Norish, Myrlin, Paseo, SparkyFitness

---

## Research

### Service Classification Summary

| Service | Type | NixOS Module | Notes |
|---------|------|--------------|-------|
| n8n | native | `services.n8n` | Good module; use `environment` for DB config |
| SearXNG | native | `services.searx` | Use `pkgs.searxng`; secret via env file |
| Nextcloud | native | `services.nextcloud` | Excellent module; use `pkgs.nextcloud32` |
| Perplexica | oci-container | none | Docker Hub `itzcrazykns1337/perplexica:slim-latest` |
| netboot.xyz | oci-container | none | Official GHCR `ghcr.io/netbootxyz/netbootxyz` |
| Norish | oci-container | none | Docker Hub `norishapp/norish:latest` |
| Myrlin | oci-container | custom build | Custom app, locally built image |
| Paseo | oci-container | custom build | Custom app, locally built image |
| SparkyFitness | oci-container | none | Two containers: frontend + backend |

---

### n8n

#### NixOS Module
- **Available:** yes
- **Module path:** `services.n8n`
- **Option coverage:** good
- **Key options:** `enable`, `openFirewall`, `environment`, `package`, `customNodes`
- **Secret handling:** Variables ending in `_FILE` are handled as systemd credentials; use `sops.templates` for env file injection
- **Default port:** 5678 (via `N8N_PORT`)

#### Environment Variables
- `DB_TYPE` — database backend (`postgresdb`) (required)
- `DB_POSTGRESDB_HOST` — postgres hostname (required)
- `DB_POSTGRESDB_PORT` — postgres port (required)
- `DB_POSTGRESDB_DATABASE` — database name (required)
- `DB_POSTGRESDB_USER` — database user (required)
- `DB_POSTGRESDB_PASSWORD` — database password (required, secret)
- `N8N_PORT` — listen port (optional, default 5678)
- `N8N_SECURE_COOKIE` — set `false` if not using HTTPS locally (optional)
- `N8N_METRICS` — enable Prometheus metrics endpoint (optional)
- `GENERIC_TIMEZONE` — timezone (optional)

#### Volumes / Data Paths
- `/var/lib/n8n` — managed by NixOS module (state directory)

#### Database
- **Type:** postgres-nas (external TrueNAS PostgreSQL at 10.10.10.20:5432)
- **DB name:** `n8n`
- **Details:** No DB management in module; create DB manually before first run

#### Auth
- **Mode:** none (n8n has built-in user management, not OIDC)
- **Details:** Caddy proxies directly; n8n's own auth handles login

#### Homepage Widget
- **Available:** no (no official homepage widget for n8n as of 2026-03)
- **Workaround:** Use `siteMonitor` only

---

### SearXNG

#### NixOS Module
- **Available:** yes
- **Module path:** `services.searx`
- **Package:** `pkgs.searxng` (not `pkgs.searx`)
- **Option coverage:** full
- **Key options:** `enable`, `redisCreateLocally`, `environmentFile`, `settings`, `package`
- **Note:** Setting `secret_key` directly in `settings` exposes it to the Nix store. Use `environmentFile` with `$SEARXNG_SECRET` placeholder instead.
- **Default port:** configured via `settings.server.port`

#### Environment Variables
- `SEARXNG_SECRET` — secret key for Flask sessions (required, secret)

#### Volumes / Data Paths
- `/var/lib/searx` — managed by NixOS module

#### Database
- **Type:** redis (local, created by `redisCreateLocally = true`)

#### Auth
- **Mode:** authelia (forward auth via Caddy — SearXNG has no built-in auth)
- **Details:** Already configured in psychosocial Caddy with `import authelia` on `@searxng`

#### Homepage Widget
- **Available:** no (no official homepage widget for SearXNG)
- **Workaround:** `siteMonitor` only; search widget already configured in psychosocial homepage

---

### Nextcloud

#### NixOS Module
- **Available:** yes
- **Module path:** `services.nextcloud`
- **Package:** `pkgs.nextcloud32` (nextcloud30 is EOL; nextcloud32 is stable for stateVersion 25.11+)
- **Option coverage:** excellent
- **Key options:** `enable`, `hostName`, `package`, `config.*`, `settings.*`, `caching.*`, `secretFile`, `maxUploadSize`
- **Default port:** 80 via nginx (module manages nginx automatically); use `nginx.listen` or `services.nextcloud.https` for HTTPS

#### Environment Variables (via `secretFile`)
- Secrets injected via `services.nextcloud.secretFile` — a JSON file containing `{"redis": {"password": "..."}}`

#### Volumes / Data Paths
- `/var/lib/nextcloud` — managed by NixOS module (data + config)
- `/var/lib/nextcloud/data` — user data

#### Database
- **Type:** postgres-nas (external TrueNAS PostgreSQL at 10.10.10.20:5432)
- **DB name:** `nextcloud`

#### Redis Caching
- Local Redis via `services.redis.servers.nextcloud`
- Redis password injected via `services.nextcloud.secretFile`

#### Auth
- **Mode:** none (Nextcloud has its own full auth; no OIDC configured currently)
- **Details:** Caddy proxies to port 80 (nginx managed by Nextcloud module)
- **Note:** Nextcloud module creates and manages nginx internally; Caddy reverse-proxies to `127.0.0.1:80`

#### Homepage Widget
- **Available:** yes
- **Type:** `nextcloud`
- **Fields:** `url`, `key` (NC-Token from Settings > System), or `username`+`password`
- **Displays:** freespace, activeusers, numfiles, numshares (max 4 fields)

---

### Perplexica

#### NixOS Module
- **Available:** no
- **Type:** oci-container
- **Image:** `itzcrazykns1337/perplexica:slim-latest` (slim = no bundled SearXNG, uses external)
- **Source:** Docker Hub (official)
- **Web UI Port:** 3000 (mapped to host 3001 to avoid conflict with Norish)
- **Docs:** https://github.com/ItzCrazyKns/Perplexica

#### Environment Variables
- `SEARXNG_API_URL` — URL of running SearXNG instance (required)

#### Volumes / Data Paths
- `perplexica-data:/home/perplexica/data` — config and settings
- `perplexica-uploads:/home/perplexica/uploads` — uploads

#### Database
- **Type:** none (file-based)

#### Auth
- **Mode:** authelia (Perplexica has no built-in auth; forward auth via Caddy)
- **Details:** Already configured in psychosocial Caddy with `import authelia` on `@perplexica`

#### Homepage Widget
- **Available:** no
- **Workaround:** `siteMonitor` only

---

### netboot.xyz

#### NixOS Module
- **Available:** no
- **Type:** oci-container
- **Image:** `ghcr.io/netbootxyz/netbootxyz` (official, GHCR — LinuxServer image is deprecated)
- **Source:** GHCR (official)
- **Web UI Port:** 3000 (mapped to host 3003 to avoid conflicts)
- **Assets Port:** 8080 (mapped to host 8086)
- **TFTP Port:** 69/udp
- **Docs:** https://github.com/netbootxyz/docker-netbootxyz

#### Environment Variables
- None required (PUID/PGID optional)

#### Volumes / Data Paths
- `/var/lib/homelab/netbootxyz/config:/config` — boot menus and config
- `/var/lib/homelab/netbootxyz/assets:/assets` — local boot assets (optional)

#### Database
- **Type:** none

#### Auth
- **Mode:** authelia (forward auth via Caddy)
- **Details:** Already configured in psychosocial Caddy with `import authelia` on `@netboot`

#### Homepage Widget
- **Available:** no
- **Workaround:** `siteMonitor` only

---

### Norish

#### NixOS Module
- **Available:** no (niche recipe app)
- **Type:** oci-container
- **Image:** `norishapp/norish:latest`
- **Source:** Docker Hub
- **Web UI Port:** 3000 (host port 3000)
- **Docs:** https://github.com/norish-recipes/norish

#### Environment Variables
- `AUTH_URL` — public URL for auth callbacks (required)
- `DATABASE_URL` — PostgreSQL connection string (required, secret)
- `MASTER_KEY` — 32+ char encryption key (required, secret)
- `REDIS_URL` — Redis connection URL (required)
- `CHROME_WS_ENDPOINT` — Playwright CDP endpoint (optional, for screenshot features)
- `OIDC_NAME` — provider display name (optional)
- `OIDC_ISSUER` — OIDC issuer URL (optional)
- `OIDC_CLIENT_ID` — client ID (optional)
- `OIDC_CLIENT_SECRET` — client secret (optional, secret)
- `TRUSTED_ORIGINS` — comma-separated trusted origins (required)

#### Volumes / Data Paths
- `/var/lib/homelab/norish/uploads:/app/uploads` — user uploads

#### Database
- **Type:** postgres-nas (external TrueNAS PostgreSQL at 10.10.10.20:5432)
- **Details:** Norish also requires Redis — use local Redis instance

#### Auth
- **Mode:** oidc (Norish supports OIDC natively; already registered in Authelia as `norish`)
- **Callback URL:** `https://norish.pytt.io/api/auth/oauth2/callback/oidc`
- **Client already registered** in `hosts/psychosocial/default.nix`

#### Homepage Widget
- **Available:** no
- **Workaround:** `siteMonitor` only

---

### Myrlin

#### NixOS Module
- **Available:** no (custom internal app)
- **Type:** oci-container (locally built image)
- **Image:** `lab-myrlin:latest` (built on-host from Dockerfile)
- **Web UI Port:** 3456
- **Docs:** internal

#### Environment Variables
- TBD based on actual app config

#### Volumes / Data Paths
- `/var/lib/homelab/myrlin:/app/state` — state data

#### Database
- **Type:** unknown (likely file-based or sqlite)

#### Auth
- **Mode:** authelia (forward auth via Caddy, unless app has own auth)

#### Homepage Widget
- **Available:** no

---

### Paseo

#### NixOS Module
- **Available:** no (custom internal app)
- **Type:** oci-container (locally built image)
- **Image:** `lab-paseo:latest` (built on-host from Dockerfile)
- **Web UI Port:** 6767
- **Docs:** internal

#### Environment Variables
- TBD based on actual app config

#### Volumes / Data Paths
- `/var/lib/homelab/paseo:/data` — data

#### Database
- **Type:** unknown

#### Auth
- **Mode:** authelia (forward auth via Caddy)

#### Homepage Widget
- **Available:** no

---

### SparkyFitness

#### NixOS Module
- **Available:** no
- **Type:** oci-container (two containers: frontend + backend)
- **Frontend Image:** `codewithcj/sparkyfitness:latest` (Nginx, port 80 → host 3004)
- **Backend Image:** `codewithcj/sparkyfitness_server:latest` (no external port needed — frontend proxies to it)
- **Source:** Docker Hub
- **Web UI Port:** 3004 (frontend)
- **Docs:** https://codewithcj.github.io/SparkyFitness/

#### Environment Variables (Backend)
- `SPARKY_FITNESS_DB_HOST` — postgres hostname (required)
- `SPARKY_FITNESS_DB_PORT` — postgres port (required)
- `SPARKY_FITNESS_DB_NAME` — database name (required)
- `SPARKY_FITNESS_DB_USER` — superuser for migrations (required)
- `SPARKY_FITNESS_DB_PASSWORD` — superuser password (required, secret)
- `SPARKY_FITNESS_APP_DB_USER` — app user (required)
- `SPARKY_FITNESS_APP_DB_PASSWORD` — app user password (required, secret)
- `SPARKY_FITNESS_API_ENCRYPTION_KEY` — 64-char hex encryption key (required, secret)
- `BETTER_AUTH_SECRET` — auth secret (required, secret)
- `SPARKY_FITNESS_FRONTEND_URL` — public frontend URL for CORS (required)
- `NODE_ENV` — `production` (required)
- `TZ` — timezone (optional)
- OIDC env vars if using OIDC (optional — has full OIDC support)

#### Environment Variables (Frontend)
- `SPARKY_FITNESS_SERVER_HOST` — backend container name or IP (required)
- `SPARKY_FITNESS_SERVER_PORT` — backend port (required)
- `SPARKY_FITNESS_FRONTEND_URL` — public URL (required)
- `TZ` — timezone (optional)

#### Volumes / Data Paths
- `/var/lib/homelab/sparkyfitness/uploads:/app/uploads` — profile images etc.

#### Database
- **Type:** postgres-nas (external TrueNAS PostgreSQL at 10.10.10.20:5432)
- **DB name:** `sparkyfitness`

#### Auth
- **Mode:** oidc (SparkyFitness supports OIDC natively) — or `authelia` forward auth if OIDC not configured
- **Details:** OIDC env vars available; configure as Authelia client (requires registering in psychosocial)

#### Homepage Widget
- **Available:** no
- **Workaround:** `siteMonitor` only

---

## Codebase State Notes

- `hosts/sugar/default.nix` exists but is a stub with only networking config and Docker enabled
- Uses `serverModules` from `parts/lib.nix` (no home-manager, no stylix)
- Secrets file `secrets/sugar.yaml` does NOT yet exist (needs creation)
- sops key tier: `homelab_general` (age1knseevsr30xnq67wuhfrtlfw43ryz4hgch3y0ae4rlppfdss6p7q0pqt6u)
- Pattern from `hosts/byob/default.nix`: native services + one OCI container coexist cleanly
- Pattern from `hosts/psychosocial/default.nix`: sops templates for env file injection
- Nextcloud module manages nginx internally; Caddy on psychosocial proxies to port 80 on sugar
- Redis: separate named instances via `services.redis.servers.<name>` to avoid conflicts

---

## Implementation Plan

### File: `hosts/sugar/default.nix` (EDIT — full replacement)

Replace the stub with the complete service configuration:

```nix
{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

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
  sops.secrets.nextcloud_redis_pass = { owner = "nextcloud"; };
  sops.secrets.nextcloud_secret_file = { owner = "nextcloud"; };

  # Norish
  sops.secrets.norish_db_pass = { };
  sops.secrets.norish_master_key = { };
  sops.secrets.norish_oidc_client_secret = { };

  # SparkyFitness
  sops.secrets.sparkyfitness_db_password = { };
  sops.secrets.sparkyfitness_app_db_password = { };
  sops.secrets.sparkyfitness_api_encryption_key = { };
  sops.secrets.sparkyfitness_auth_secret = { };
  sops.secrets.sparkyfitness_oidc_client_secret = { };

  # --- Firewall ---
  networking.firewall = {
    allowedTCPPorts = [
      80      # Nextcloud (nginx managed by module)
      3000    # Norish
      3001    # Perplexica
      3003    # netboot.xyz web UI
      3004    # SparkyFitness frontend
      3456    # Myrlin
      5678    # n8n
      6767    # Paseo
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
    {"redis":{"password":"${config.sops.placeholder.nextcloud_redis_pass}"}}
  '';

  sops.templates."norish-env".content = ''
    AUTH_URL=https://norish.pytt.io
    DATABASE_URL=postgres://norish:${config.sops.placeholder.norish_db_pass}@10.10.10.20:5432/norish
    MASTER_KEY=${config.sops.placeholder.norish_master_key}
    REDIS_URL=redis://:norish@127.0.0.1:6380
    OIDC_NAME=Authelia
    OIDC_ISSUER=https://auth.pytt.io
    OIDC_CLIENT_ID=norish
    OIDC_CLIENT_SECRET=${config.sops.placeholder.norish_oidc_client_secret}
    TRUSTED_ORIGINS=https://norish.pytt.io
  '';

  sops.templates."sparkyfitness-backend-env".content = ''
    SPARKY_FITNESS_DB_HOST=10.10.10.20
    SPARKY_FITNESS_DB_PORT=5432
    SPARKY_FITNESS_DB_NAME=sparkyfitness
    SPARKY_FITNESS_DB_USER=sparkyfitness
    SPARKY_FITNESS_DB_PASSWORD=${config.sops.placeholder.sparkyfitness_db_password}
    SPARKY_FITNESS_APP_DB_USER=sparkyfitness_app
    SPARKY_FITNESS_APP_DB_PASSWORD=${config.sops.placeholder.sparkyfitness_app_db_password}
    SPARKY_FITNESS_API_ENCRYPTION_KEY=${config.sops.placeholder.sparkyfitness_api_encryption_key}
    BETTER_AUTH_SECRET=${config.sops.placeholder.sparkyfitness_auth_secret}
    SPARKY_FITNESS_FRONTEND_URL=https://sparkyfitness.pytt.io
    SPARKY_FITNESS_OIDC_AUTH_ENABLED=true
    SPARKY_FITNESS_OIDC_PROVIDER_SLUG=authelia
    SPARKY_FITNESS_OIDC_PROVIDER_NAME=Authelia
    SPARKY_FITNESS_OIDC_AUTO_REGISTER=true
    SPARKY_FITNESS_OIDC_ISSUER_URL=https://auth.pytt.io
    SPARKY_FITNESS_OIDC_CLIENT_ID=sparkyfitness
    SPARKY_FITNESS_OIDC_CLIENT_SECRET=${config.sops.placeholder.sparkyfitness_oidc_client_secret}
    SPARKY_FITNESS_OIDC_SCOPE=openid profile email
    NODE_ENV=production
    TZ=Europe/Oslo
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
    requirePassFile = config.sops.secrets.nextcloud_redis_pass.path;
  };

  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.pytt.io";
    package = pkgs.nextcloud32;
    maxUploadSize = "1G";

    config = {
      adminuser = "admin";
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
      dbtype = "pgsql";
      dbhost = "10.10.10.20";
      dbport = 5432;
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

    # Myrlin — custom internal app (locally built)
    myrlin = {
      image = "lab-myrlin:latest";
      volumes = [
        "/var/lib/homelab/myrlin/state:/app/state"
      ];
      ports = [ "3456:3456" ];
      extraOptions = [ "--network=iowa" ];
    };

    # Paseo — custom internal app (locally built)
    paseo = {
      image = "lab-paseo:latest";
      volumes = [
        "/var/lib/homelab/paseo/data:/data"
      ];
      ports = [ "6767:6767" ];
      extraOptions = [ "--network=iowa" ];
    };

    # SparkyFitness backend — Node.js API server
    sparkyfitness-backend = {
      image = "codewithcj/sparkyfitness_server:latest";
      environmentFiles = [ config.sops.templates."sparkyfitness-backend-env".path ];
      volumes = [
        "/var/lib/homelab/sparkyfitness/uploads:/app/uploads"
      ];
      extraOptions = [ "--network=iowa" "--name=sparkyfitness-backend" ];
    };

    # SparkyFitness frontend — Nginx serving React app
    sparkyfitness-frontend = {
      image = "codewithcj/sparkyfitness:latest";
      environment = {
        SPARKY_FITNESS_FRONTEND_URL = "https://sparkyfitness.pytt.io";
        SPARKY_FITNESS_SERVER_HOST = "sparkyfitness-backend";
        SPARKY_FITNESS_SERVER_PORT = "3010";
        TZ = "Europe/Oslo";
      };
      ports = [ "3004:80" ];
      extraOptions = [ "--network=iowa" "--name=sparkyfitness-frontend" ];
      dependsOn = [ "sparkyfitness-backend" ];
    };

  };

  # Norish also needs Redis — separate named instance on port 6380
  services.redis.servers.norish = {
    enable = true;
    port = 6380;
    bind = "127.0.0.1";
    # No password required for local-only access by Norish
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
    "d /var/lib/homelab/myrlin 0755 root root -"
    "d /var/lib/homelab/myrlin/state 0755 root root -"
    "d /var/lib/homelab/paseo 0755 root root -"
    "d /var/lib/homelab/paseo/data 0755 root root -"
    "d /var/lib/homelab/sparkyfitness 0755 root root -"
    "d /var/lib/homelab/sparkyfitness/uploads 0755 root root -"
  ];

  system.stateVersion = "25.05";
}
```

---

### File: `secrets/sugar.yaml` (CREATE)

Create this file with `sops secrets/sugar.yaml` using the `homelab_general` age key. Add these encrypted secrets:

```
# n8n
n8n_db_password: <postgres password for n8n user>

# SearXNG
searxng_secret: <random 32+ char secret>

# Nextcloud
nextcloud_admin_pass: <nextcloud admin password>
nextcloud_db_pass: <postgres password for nextcloud user>
nextcloud_redis_pass: <redis password for nextcloud cache>
nextcloud_secret_file: <not used directly — injected via template>

# Norish
norish_db_pass: <postgres password for norish user>
norish_master_key: <32+ char master key>
norish_oidc_client_secret: <plain text secret — same as hashed version in psychosocial>

# SparkyFitness
sparkyfitness_db_password: <postgres superuser password>
sparkyfitness_app_db_password: <postgres app user password>
sparkyfitness_api_encryption_key: <64-char hex string>
sparkyfitness_auth_secret: <strong random secret>
sparkyfitness_oidc_client_secret: <plain text OIDC secret>
```

Commands:
```bash
sops secrets/sugar.yaml
# Add keys above, save and exit
git add secrets/sugar.yaml
```

---

### File: `hosts/psychosocial/default.nix` (EDIT) — Update Caddy sugar routes to staging IP

The Caddy config already has all sugar routes pointing at `10.10.30.11` (old Ubuntu VM). During staging, temporarily update the sugar routes to point at `10.10.30.111`:

```nix
# --- sugar (staging: 10.10.30.111) ---

@n8n host n8n.pytt.io
handle @n8n {
  reverse_proxy 10.10.30.111:5678
}

@nextcloud host nextcloud.pytt.io
handle @nextcloud {
  reverse_proxy 10.10.30.111:80
}

@norish host norish.pytt.io
handle @norish {
  reverse_proxy 10.10.30.111:3000
}

@myrlin host myrlin.pytt.io
handle @myrlin {
  reverse_proxy 10.10.30.111:3456
}

@paseo host paseo.pytt.io
handle @paseo {
  reverse_proxy 10.10.30.111:6767
}

@searxng host searxng.pytt.io
handle @searxng {
  import authelia
  reverse_proxy 10.10.30.111:8888
}

@perplexica host perplexica.pytt.io
handle @perplexica {
  import authelia
  reverse_proxy 10.10.30.111:3001
}

@sparkyfitness host sparkyfitness.pytt.io
handle @sparkyfitness {
  reverse_proxy 10.10.30.111:3004
}

@netboot host netboot.pytt.io
handle @netboot {
  import authelia
  reverse_proxy 10.10.30.111:3003
}
```

After IP cutover, change all `10.10.30.111` back to `10.10.30.11`.

---

### File: `hosts/psychosocial/default.nix` (EDIT) — Add SparkyFitness OIDC client to Authelia

Add a new OIDC client entry in `services.authelia.instances.main.settings.identity_providers.oidc.clients`:

```nix
{
  client_id = "sparkyfitness";
  client_name = "SparkyFitness";
  # Generate hash with: authelia crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.characters rfc3986
  client_secret = "$pbkdf2-sha512$310000$<salt>$<hash>";
  public = false;
  authorization_policy = "one_factor";
  redirect_uris = [ "https://sparkyfitness.pytt.io/api/auth/callback/authelia" ];
  scopes = [ "openid" "profile" "email" ];
  userinfo_signed_response_alg = "none";
}
```

---

### File: `hosts/psychosocial/default.nix` (EDIT) — Add Nextcloud and SparkyFitness to Homepage services

Add under the `Main` group:

```nix
{
  SparkyFitness = {
    icon = "mdi-dumbbell";
    href = "https://sparkyfitness.pytt.io";
    description = "Fitness & Nutrition Tracker";
    siteMonitor = "http://10.10.30.111:3004";
  };
}
```

Nextcloud already appears in the `Main` group; update its `siteMonitor` to staging IP:
```nix
{
  Nextcloud = {
    icon = "nextcloud.png";
    href = "https://nextcloud.pytt.io";
    description = "File Storage & Collaboration";
    siteMonitor = "http://10.10.30.111:80";
    widget = {
      type = "nextcloud";
      url = "https://nextcloud.pytt.io";
      key = "{{HOMEPAGE_VAR_NEXTCLOUD_TOKEN}}";
    };
  };
}
```

Add `homepage_nextcloud_token` secret:

```nix
# In psychosocial/default.nix
sops.secrets.homepage_nextcloud_token = { };

# In sops.templates."homepage-env".content
HOMEPAGE_VAR_NEXTCLOUD_TOKEN=${config.sops.placeholder.homepage_nextcloud_token}
```

And add to `secrets/psychosocial.yaml`:
```
homepage_nextcloud_token: <Nextcloud NC-Token from Settings > System>
```

---

### Manual Steps

#### Pre-deploy

1. **Create PostgreSQL databases on TrueNAS** (10.10.10.20):
   ```sql
   -- Connect as postgres superuser
   CREATE USER n8n WITH PASSWORD '<password>';
   CREATE DATABASE n8n OWNER n8n;

   CREATE USER nextcloud WITH PASSWORD '<password>';
   CREATE DATABASE nextcloud OWNER nextcloud;

   CREATE USER norish WITH PASSWORD '<password>';
   CREATE DATABASE norish OWNER norish;

   CREATE USER sparkyfitness WITH PASSWORD '<password>';
   CREATE DATABASE sparkyfitness OWNER sparkyfitness;
   CREATE USER sparkyfitness_app WITH PASSWORD '<password>';
   GRANT CONNECT ON DATABASE sparkyfitness TO sparkyfitness_app;
   ```

2. **Create `secrets/sugar.yaml`** using sops:
   ```bash
   sops secrets/sugar.yaml
   # Populate all secrets listed above
   git add secrets/sugar.yaml
   ```

3. **Copy age key** to new sugar NixOS VM:
   ```bash
   ssh root@10.10.30.111 mkdir -p /etc/homelab/sops
   scp /etc/homelab/sops/keys.txt root@10.10.30.111:/etc/homelab/sops/keys.txt
   ssh root@10.10.30.111 chmod 400 /etc/homelab/sops/keys.txt
   ```

4. **Build custom Docker images** on the new sugar VM (for Myrlin and Paseo):
   ```bash
   # Transfer Dockerfiles from old Ubuntu VM
   rsync -avz root@10.10.30.11:/path/to/myrlin/ root@10.10.30.111:/tmp/myrlin/
   rsync -avz root@10.10.30.11:/path/to/paseo/ root@10.10.30.111:/tmp/paseo/
   # Build images
   ssh root@10.10.30.111 docker build -t lab-myrlin:latest /tmp/myrlin/
   ssh root@10.10.30.111 docker build -t lab-paseo:latest /tmp/paseo/
   ```

5. **Migrate data from old Ubuntu VM** (after initial deploy, before traffic cutover):
   ```bash
   # Norish uploads
   rsync -avz root@10.10.30.11:/var/lib/homelab/norish/ root@10.10.30.111:/var/lib/homelab/norish/
   # netboot.xyz config (if any customization exists)
   rsync -avz root@10.10.30.11:/var/lib/homelab/netbootxyz/ root@10.10.30.111:/var/lib/homelab/netbootxyz/
   # Myrlin/Paseo state
   rsync -avz root@10.10.30.11:/var/lib/homelab/myrlin/ root@10.10.30.111:/var/lib/homelab/myrlin/
   rsync -avz root@10.10.30.11:/var/lib/homelab/paseo/ root@10.10.30.111:/var/lib/homelab/paseo/
   # SparkyFitness uploads
   rsync -avz root@10.10.30.11:/var/lib/homelab/sparkyfitness/ root@10.10.30.111:/var/lib/homelab/sparkyfitness/
   ```

6. **Migrate n8n data** (if using SQLite on old server, or ensure postgres DB is populated):
   ```bash
   # If old n8n uses SQLite, export workflows and credentials first via n8n UI
   # Then import on new instance after first boot
   ```

7. **Generate SparkyFitness OIDC client hash** for Authelia:
   ```bash
   nix run nixpkgs#authelia -- crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.characters rfc3986
   # Use the hash in psychosocial default.nix, plain text in secrets/sugar.yaml
   ```

8. **Nextcloud first-run setup** — after deploy, Nextcloud runs `nextcloud-setup.service` automatically. Monitor with:
   ```bash
   journalctl -u nextcloud-setup.service -f
   ```

9. **Get Nextcloud NC-Token** for Homepage widget:
   - Login to `https://nextcloud.pytt.io`
   - Go to Settings > System > API keys
   - Generate token, add to `secrets/psychosocial.yaml` as `homepage_nextcloud_token`

#### Post-deploy Verification

1. Check all native services are running:
   ```bash
   systemctl status n8n searx nextcloud-setup nextcloud redis-nextcloud redis-norish
   ```

2. Check all Docker containers are running:
   ```bash
   docker ps
   ```

3. Check logs for issues:
   ```bash
   journalctl -u n8n -u searx -u nextcloud-setup --since "5 minutes ago"
   docker logs norish
   docker logs sparkyfitness-backend
   ```

4. Test service endpoints from sugar host:
   ```bash
   curl http://127.0.0.1:5678/healthz    # n8n
   curl http://127.0.0.1:8888/stats      # SearXNG
   curl http://127.0.0.1/status.php      # Nextcloud
   curl http://127.0.0.1:3001            # Perplexica
   curl http://127.0.0.1:3000            # Norish
   curl http://127.0.0.1:3004            # SparkyFitness frontend
   ```

5. Verify SOPS secrets decrypted:
   ```bash
   ls -la /run/secrets/
   ls -la /run/secrets.d/
   ```

6. Update psychosocial Caddy routes to point at staging IP (10.10.30.111) and verify end-to-end:
   ```bash
   curl -H "Host: n8n.pytt.io" https://10.10.30.110/healthz
   ```

#### IP Cutover

1. Update sugar staging IP to production IP in `hosts/sugar/default.nix`:
   ```nix
   address = "10.10.30.11";
   ```

2. Update psychosocial Caddy routes back to `10.10.30.11`

3. Stop old Ubuntu sugar VM on Proxmox

4. Deploy:
   ```bash
   colmena apply --on sugar
   colmena apply --on psychosocial
   ```

---

### Verification

- `nix flake check` passes
- `colmena apply --on sugar` deploys successfully
- `systemctl status n8n` shows active
- `systemctl status searx` shows active
- `systemctl status nextcloud-setup` completed successfully
- `docker ps` shows all 7 OCI containers running
- Web UI accessible at:
  - `https://n8n.pytt.io`
  - `https://searxng.pytt.io`
  - `https://nextcloud.pytt.io`
  - `https://perplexica.pytt.io`
  - `https://netboot.pytt.io`
  - `https://norish.pytt.io`
  - `https://myrlin.pytt.io`
  - `https://paseo.pytt.io`
  - `https://sparkyfitness.pytt.io`
- Nextcloud Homepage widget shows freespace/activeusers
- Norish OIDC login via Authelia works
- SparkyFitness OIDC login via Authelia works (after client registered)

---

## Pre-deploy Checklist

- [ ] **PostgreSQL databases** created on TrueNAS (n8n, nextcloud, norish, sparkyfitness)
- [ ] **`secrets/sugar.yaml`** created with all secrets via SOPS
- [ ] **Age key** copied to `/etc/homelab/sops/keys.txt` on new sugar VM
- [ ] **Custom Docker images** built on sugar VM (lab-myrlin, lab-paseo)
- [ ] **Data migrated** from old Ubuntu sugar VM
- [ ] **SparkyFitness OIDC hash** generated and added to psychosocial Authelia config
- [ ] **Nextcloud NC-Token** obtained post-deploy and added to psychosocial secrets
- [ ] **Caddy routes** on psychosocial updated to staging IP (10.10.30.111) for testing
- [ ] **Host config** — full `hosts/sugar/default.nix` written
- [ ] **Firewall** — all ports opened in `networking.firewall`
- [ ] **`sops.defaultSopsFile`** uncommented in sugar default.nix
- [ ] **flake check** — `nix flake check` passes
- [ ] **Deploy** — `colmena apply --on sugar` succeeds
- [ ] **End-to-end test** — all subdomains resolve via Caddy reverse proxy

---

## Known Quirks & Gotchas

1. **Nextcloud + nginx**: The `services.nextcloud` module manages nginx internally. Do NOT configure nginx separately for Nextcloud. Caddy proxies to the nginx-served port (80). The module also sets up the occ CLI tool, cron job, and PHP-FPM automatically.

2. **Nextcloud `trusted_proxies`**: Must include psychosocial's IP so Nextcloud accepts the `X-Forwarded-For` header from Caddy. During staging, use `10.10.30.110`; after cutover, update to `10.10.30.10`.

3. **Nextcloud package version**: Use `pkgs.nextcloud32` explicitly. Do not let it auto-select based on `stateVersion`. If migrating from Nextcloud 30 on the old server, you must upgrade one major version at a time: 30 → 31 → 32 (each requires a `colmena apply` + `occ upgrade`).

4. **SearXNG secret_key**: The `$SEARXNG_SECRET` placeholder in `settings.server.secret_key` is replaced at runtime from the `environmentFile`. This only works because the NixOS module evaluates it when constructing the settings.yml. If this causes issues, use `settingsFile` option to provide a pre-rendered file from sops.

5. **Perplexica `slim-latest`**: This image requires a running SearXNG instance. Perplexica connects to `127.0.0.1:8888` (SearXNG) at the host network level. The `--network=iowa` Docker network is for inter-container communication but Perplexica → SearXNG uses host loopback. Consider using `--network=host` for Perplexica if `127.0.0.1` resolution fails from within the container.

6. **n8n DynamicUser**: The NixOS n8n module uses `DynamicUser=true` by default. Variables ending in `_FILE` are loaded as systemd credentials. Using an external `EnvironmentFile` via `serviceConfig.EnvironmentFile` overrides this mechanism — verify n8n reads DB credentials from the injected env file correctly.

7. **Norish Redis**: Norish requires Redis in addition to PostgreSQL. A local Redis instance is configured on port 6380 to avoid conflicting with the SearXNG Redis (managed by `redisCreateLocally` on default port 6379).

8. **SparkyFitness `dependsOn`**: The frontend container must start after the backend. The `dependsOn` field in NixOS OCI containers generates a `--link` or `after:` dependency in the systemd unit. Verify both containers are in the same Docker network.

9. **Myrlin/Paseo images**: These are locally built and not in any registry. They must be manually rebuilt after OS reinstall or major Docker changes. Consider documenting the build process or adding a Dockerfile to this flake repo.

10. **netboot.xyz TFTP port 69**: Port 69 is below 1024, which normally requires root or `CAP_NET_BIND_SERVICE`. Docker handles this correctly when the container is started as root. Verify the firewall UDP rule is applied.
