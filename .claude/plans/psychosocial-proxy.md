# Psychosocial — Caddy + Authelia Reverse Proxy

**Status:** plan-complete
**Host:** psychosocial (staging: 10.10.30.110)
**Date:** 2026-03-08
**Type:** native modules (services.caddy + services.authelia)

---

## Research

### NixOS Modules
- **Caddy:** `services.caddy` — full module, supports `withPlugins`, `globalConfig`, `extraConfig`, `virtualHosts`
- **Authelia:** `services.authelia.instances.<name>` — full module with typed secrets support

### Caddy Cloudflare DNS Plugin
- Plugin: `github.com/caddy-dns/cloudflare`
- Method: `pkgs.caddy.withPlugins { plugins = [...]; hash = "sha256-..."; }`
- Hash must be obtained from first failed build (nix will print the correct hash)
- Version to use: latest tag — check https://github.com/caddy-dns/cloudflare/releases

### TLS Strategy
Use a single wildcard `*.pytt.io` block (mirrors existing Caddyfile) via `services.caddy.extraConfig`.
This gets **one wildcard cert** via DNS-01 instead of per-subdomain certs.
Cloudflare API token injected via `systemd.services.caddy.serviceConfig.EnvironmentFile` pointing to a sops secret.

### Authelia
- Native NixOS module — settings map directly from old `configuration.yml`
- Secrets via `services.authelia.instances.main.secrets.*` (sops file paths)
- Users database — password hashes are argon2id (not raw secrets), safe in nix store via `environment.etc`
- Redis session storage: TrueNAS at `10.10.10.20:30059`
- Storage: local SQLite at `/var/lib/authelia-main/` (NixOS default data dir)

### Existing Docker Caddyfile (reference)
Located at `~/Projects/Privat/DockerLab/psychosocial/configs/caddyfile/Caddyfile`

### Services being proxied
| Service | Host | Port | Auth |
|---------|------|------|------|
| auth | local (authelia) | 9091 | bypass |
| home | local (homepage, TODO) | 3000 | authelia |
| sonarr | byob 10.10.50.110 | 8989 | none |
| radarr | byob 10.10.50.110 | 7878 | none |
| lidarr | byob 10.10.50.110 | 8686 | none |
| prowlarr | byob 10.10.50.110 | 9696 | none |
| nzbget | byob 10.10.50.110 | 6789 | none |
| transmission | byob 10.10.50.110 | 9091 | none |
| jellyseerr | byob 10.10.50.110 | 5055 | none |
| huntarr | byob 10.10.50.110 | 9705 | none |
| gatus | pulse 10.10.30.112 | 8080 | none |
| grafana | pulse 10.10.30.112 | 3000 | none |
| prometheus | pulse 10.10.30.112 | 9090 | authelia |
| n8n | sugar 10.10.30.111 | 5678 | none |
| nextcloud | sugar 10.10.30.111 | 8080 | none |
| norish | sugar 10.10.30.111 | 3000 | none |
| myrlin | sugar 10.10.30.111 | 3456 | none |
| paseo | sugar 10.10.30.111 | 6767 | none |
| searxng | sugar 10.10.30.111 | 8888 | authelia |
| perplexica | sugar 10.10.30.111 | 3001 | authelia |
| sparkyfitness | sugar 10.10.30.111 | 3004 | none |
| netboot | sugar 10.10.30.111 | 3003 | authelia |
| jellyfin | truenas 10.10.10.20 | 30013 | none |
| pve1 | 10.10.10.227 | 8006 | none (HTTPS+skip_verify) |
| pve2 | 10.10.10.228 | 8006 | none (HTTPS+skip_verify) |
| truenas | 10.10.10.20 | 443 | none (HTTPS+skip_verify) |
| craftbeerpi | 10.10.20.174 | 8000 | none |
| homeassistant | 10.10.20.205 | 8123 | none |
| ollama | 192.168.1.91 | 11434 | none |

Note: byob services point to **staging IP (10.10.50.110)** now. Other servers still point to old IPs until migrated.

---

## Implementation Plan

### Step 1: Get the Caddy withPlugins hash

First, find the latest cloudflare caddy-dns version:
```
https://github.com/caddy-dns/cloudflare/releases
```

Then build with a fake hash to get the real one:
```nix
# Temporarily add to hosts/psychosocial/default.nix:
environment.systemPackages = [
  (pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  })
];
```
Run `nix build .#nixosConfigurations.psychosocial.config.system.build.toplevel 2>&1 | grep "got:"` — use the hash from the error output.

---

### Step 2: File `secrets/psychosocial.yaml` (CREATE via SOPS)

First get the psychosocial age key:
```bash
ssh odin@10.10.30.110 "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
```
Update `.sops.yaml` — replace `REPLACE_WITH_CRITICAL_AGE_KEY` with the real key.

Then create the secrets file:
```bash
sops secrets/psychosocial.yaml
```

Add these keys:
```yaml
caddy_cloudflare_api_token: "CF_API_TOKEN_HERE"
authelia_jwt_secret: "generate: openssl rand -hex 32"
authelia_session_secret: "generate: openssl rand -hex 32"
authelia_storage_encryption_key: "generate: openssl rand -hex 32"
authelia_oidc_hmac_secret: "generate: openssl rand -hex 32"
authelia_oidc_private_key: |
  -----BEGIN RSA PRIVATE KEY-----
  ... (generate: openssl genrsa 4096 2>/dev/null)
  -----END RSA PRIVATE KEY-----
```

Generate values:
```bash
openssl rand -hex 32   # for each _secret/_key
openssl genrsa 4096 2>/dev/null  # for oidc_private_key
```

---

### Step 3: File `hosts/psychosocial/default.nix` (EDIT — full replacement)

```nix
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
  sops.secrets.authelia_oidc_private_key = { owner = "authelia-main"; };

  # --- Authelia users database (password hashes only — safe in store) ---
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
      oidcIssuerPrivateKeyFile = config.sops.secrets.authelia_oidc_private_key.path;
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

      session.cookies = [
        {
          domain = "pytt.io";
          authelia_url = "https://auth.pytt.io";
          default_redirection_url = "https://home.pytt.io";
        }
      ];

      session.redis = {
        host = "10.10.10.20";
        port = 30059;
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
            domain = "auth.pytt.io";
            policy = "bypass";
          }
          {
            domain = [
              "pve1.pytt.io"
              "truenas.pytt.io"
            ];
            policy = "one_factor";
            subject = [ "group:admins" ];
          }
          {
            domain = [ "pve2.pytt.io" ];
            policy = "two_factor";
            subject = [ "group:admins" ];
          }
          {
            domain = [ "*.pytt.io" ];
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
            "https://pve1.pytt.io"
            "https://pve2.pytt.io"
          ];
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

  # --- Caddy ---
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];  # UPDATE version + hash
      hash = "sha256-REPLACE_WITH_REAL_HASH";
    };
    globalConfig = ''
      admin 0.0.0.0:2019
      acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
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

        # TODO: add @home when homepage is deployed
        # @home host home.pytt.io
        # handle @home {
        #   import authelia
        #   reverse_proxy 127.0.0.1:3000
        # }

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

        # --- pulse (staging: 10.10.30.112) ---

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
          reverse_proxy 10.10.30.111:8080
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

        # TODO: reverse_proxy 127.0.0.1:3000 when homepage is deployed
        respond "Coming soon" 200
      }
    '';
  };

  # Inject Cloudflare API token into Caddy's environment
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."caddy-env".path;

  networking.firewall.allowedTCPPorts = [
    80    # Caddy HTTP (redirects to HTTPS)
    443   # Caddy HTTPS
    9959  # Authelia metrics (Prometheus scrape)
  ];

  system.stateVersion = "25.05";
}
```

---

### Step 4: File `.sops.yaml` (EDIT)

Replace `REPLACE_WITH_CRITICAL_AGE_KEY` with the actual psychosocial age key:
```bash
ssh odin@10.10.30.110 "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
```
Then update the `homelab_critical` key anchor in `.sops.yaml`.

---

## Pre-deploy Checklist

- [ ] **psychosocial VM exists** — booted from installer ISO, nixos-anywhere deployed
- [ ] **SOPS age key** — get from `ssh-to-age` on psychosocial's SSH host key, update `.sops.yaml`
- [ ] **Secrets file** — `secrets/psychosocial.yaml` created with all 6 secrets
- [ ] **Cloudflare API token** — token with `Zone:DNS:Edit` permission for `pytt.io`
- [ ] **Caddy withPlugins hash** — obtained from failed nix build with fake hash
- [ ] **cloudflare caddy-dns version** — confirm latest tag at github.com/caddy-dns/cloudflare
- [ ] **Port 80 open** — added to `networking.firewall.allowedTCPPorts` (Caddy needs it for ACME)
- [ ] **flake check** — `nix flake check` passes
- [ ] **Deploy** — `colmena apply --on psychosocial`
- [ ] **DNS cutover** — update Cloudflare DNS A record for `*.pytt.io` from old psychosocial IP to new staging IP `10.10.30.110`

## Verification

- `systemctl status caddy` — active
- `systemctl status authelia-main` — active
- `https://auth.pytt.io` — Authelia login page loads
- `https://sonarr.pytt.io` — proxies to byob staging
- `https://grafana.pytt.io` — loads (once pulse is deployed)

## Notes

- **Authelia listens on 127.0.0.1:9091** (not 0.0.0.0) — Caddy is local, no need to expose it
- **Redis password**: The old Docker config used `AUTHELIA_SESSION_REDIS_PASSWORD`. If the TrueNAS Redis instance requires a password, add it to the sops secrets and set `session.redis.password_file` in the Authelia settings
- **OIDC client secrets**: The pbkdf2 hashes in OIDC clients are already hashed — they're safe in the nix store. The actual plaintext client secrets are only needed when registering OIDC apps (Proxmox, Norish, Gatus, Grafana) — keep these in your password manager
- **huntarr** — not yet deployed on byob (port 9705). Add it when ready
- **After DNS cutover**: Remove the old Docker psychosocial from Proxmox
