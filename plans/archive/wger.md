# wger Workout Manager

**Status:** plan-complete
**Host:** sugar
**Date:** 2026-03-14
**Type:** oci-container

## Research

### NixOS Module
- **Available:** no
- **Module path:** N/A
- **Option coverage:** none
- **Details:** No `services.wger` NixOS module exists. No wger package in nixpkgs. OCI container is the correct deployment method.

### Image (OCI)
- **Reference:** `docker.io/wger/server:latest`
- **Source:** Docker Hub (official wger project)
- **Web UI Port:** 8000 (internal; nginx fronts it in the official compose, but we reverse-proxy directly from Caddy on psychosocial)
- **Docs:** https://wger.readthedocs.io/en/latest/production/docker.html

wger requires three running processes from the same image:
1. **web** — gunicorn app server (port 8000)
2. **celery-worker** — async task queue (`/start-worker`)
3. **celery-beat** — periodic task scheduler (`/start-beat`)

We will run all three as separate OCI containers sharing the same env file.

### Environment Variables
- `SECRET_KEY` — Django secret key (required, must be long random string)
- `SIGNING_KEY` — JWT signing key (required, must be long random string)
- `SITE_URL` — Public URL e.g. `https://wger.pytt.io` (required)
- `CSRF_TRUSTED_ORIGINS` — Same as SITE_URL (required when behind proxy)
- `X_FORWARDED_PROTO_HEADER_SET` — `True` (required behind reverse proxy)
- `DJANGO_DB_ENGINE` — `django.db.backends.postgresql` (required)
- `DJANGO_DB_DATABASE` — `wger` (required)
- `DJANGO_DB_USER` — `wger` (required)
- `DJANGO_DB_PASSWORD` — postgres password (required, secret)
- `DJANGO_DB_HOST` — `10.10.10.20` (TrueNAS postgres, required)
- `DJANGO_DB_PORT` — `5432` (required)
- `DJANGO_CACHE_BACKEND` — `django_redis.cache.RedisCache` (required)
- `DJANGO_CACHE_LOCATION` — Redis URL with DB index (required)
- `CELERY_BROKER` — Redis URL for Celery broker (required)
- `CELERY_BACKEND` — Redis URL for Celery result backend (required)
- `USE_CELERY` — `True` (required for background tasks)
- `ALLOW_REGISTRATION` — `False` (recommended; auth proxy handles users)
- `ALLOW_GUEST_USERS` — `False` (recommended)
- `TIME_ZONE` — `Europe/Oslo` (optional, match host)
- `TZ` — `Europe/Oslo` (optional)
- `DJANGO_PERFORM_MIGRATIONS` — `True` (auto-migrate on startup)
- `AUTH_PROXY_HEADER` — `HTTP_REMOTE_USER` (for Authelia forward auth)
- `AUTH_PROXY_TRUSTED_IPS` — `10.10.30.110` (psychosocial staging IP)
- `AUTH_PROXY_CREATE_UNKNOWN_USER` — `True` (auto-create users on first SSO login)
- `EXPOSE_PROMETHEUS_METRICS` — `False` (optional)
- `WGER_USE_GUNICORN` — `True` (default, ensures gunicorn is used)
- `NUMBER_OF_PROXIES` — `1` (one reverse proxy in front)

### Volumes / Data Paths
- `/home/wger/static` — Static files (CSS/JS/images). In the official compose, nginx serves these. Since we reverse-proxy the gunicorn port directly, we still need to mount this but the app serves them internally via whitenoise.
- `/home/wger/media` — User-uploaded media (workout images, etc.) — must persist

### Database
- **Type:** postgres (external — TrueNAS at 10.10.10.20)
- **Details:** Requires a `wger` database and `wger` user on the existing TrueNAS PostgreSQL instance. No minimum version constraint beyond PostgreSQL 12+; TrueNAS runs PostgreSQL 15 based on the n8n config pattern. Migrations run automatically on container startup via `DJANGO_PERFORM_MIGRATIONS=True`.

### Redis
- **Type:** existing named Redis instance on sugar
- **Details:** Sugar already has two named Redis instances:
  - `nextcloud` — port 6379 (used by Nextcloud)
  - `norish` — port 6380 (used by Norish)

  Per user requirement, we integrate with existing Redis rather than adding a new service. We will reuse the `norish` Redis instance (port 6380, password from `redis_pass` secret) with **separate DB indices** to avoid collisions:
  - DB 1 → Norish uses for its REDIS_URL (check norish-env: `redis://:${redis_pass}@127.0.0.1:6380` — norish does not specify a DB index, which defaults to DB 0)
  - DB 1 → wger cache (`DJANGO_CACHE_LOCATION`)
  - DB 2 → wger Celery broker/backend (`CELERY_BROKER`, `CELERY_BACKEND`)

  Since norish uses DB 0 (no index specified), wger uses DB 1 and DB 2 on the same Redis instance at port 6380 without conflict.

  The Redis password must be embedded in the URL: `redis://:${redis_pass}@127.0.0.1:6380/1`

### Auth
- **Mode:** authelia (forward auth via Caddy + wger auth proxy header)
- **Details:** wger does not natively support OIDC. It supports reverse-proxy header delegation via `AUTH_PROXY_HEADER`. The Caddy config on psychosocial will use `import authelia` (forward_auth to Authelia at 9091), which sets the `Remote-User` header. wger reads this as `HTTP_REMOTE_USER`. Users are auto-created on first login via `AUTH_PROXY_CREATE_UNKNOWN_USER=True`.

  See: https://wger.readthedocs.io/en/latest/administration/auth_proxy.html

  **Important:** The Caddy `forward_auth` snippet must be used, not just `import authelia`. The `Remote-User` header is set by Authelia and forwarded to wger. The wger API endpoints (`/api/v2/`) should bypass auth proxy so the mobile app and API tokens work correctly.

### Homepage Widget
- **Available:** no
- **Details:** No wger widget listed on https://gethomepage.dev/widgets/services/ — use `siteMonitor` only.

### Notes
- The official compose uses nginx to serve static files. Since we're pointing Caddy directly at gunicorn port 8000, static files will be served by gunicorn/whitenoise (wger bundles whitenoise). No separate nginx container needed.
- Celery worker and beat must run as separate containers using the same image and env file.
- The `celery-beat` container needs a writable volume for the beat schedule database at `/home/wger/beat/`.
- `ALLOW_REGISTRATION=False` and `ALLOW_GUEST_USERS=False` lock down the instance so only SSO-authenticated users (via Authelia proxy header) can access it.
- wger performs database migrations on startup automatically — no manual `manage.py migrate` needed.
- After first deploy, an admin user must be created manually or the auto-created user from first SSO login must be promoted to staff/superuser via the Django admin shell.

---

## Implementation Plan

### File: `hosts/sugar/default.nix` (EDIT)

#### 1. Add SOPS secrets

Add after the existing `norish_oidc_client_secret` secret block:

```nix
  # wger
  sops.secrets.wger_secret_key = { };
  sops.secrets.wger_signing_key = { };
  sops.secrets.wger_db_pass = { };
```

#### 2. Add SOPS env template

Add after the `norish-env` template block:

```nix
  sops.templates."wger-env".content = ''
    SECRET_KEY=${config.sops.placeholder.wger_secret_key}
    SIGNING_KEY=${config.sops.placeholder.wger_signing_key}
    SITE_URL=https://wger.pytt.io
    CSRF_TRUSTED_ORIGINS=https://wger.pytt.io
    X_FORWARDED_PROTO_HEADER_SET=True
    TIME_ZONE=Europe/Oslo
    TZ=Europe/Oslo
    DJANGO_DB_ENGINE=django.db.backends.postgresql
    DJANGO_DB_DATABASE=wger
    DJANGO_DB_USER=wger
    DJANGO_DB_PASSWORD=${config.sops.placeholder.wger_db_pass}
    DJANGO_DB_HOST=10.10.10.20
    DJANGO_DB_PORT=5432
    DJANGO_PERFORM_MIGRATIONS=True
    DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
    DJANGO_CACHE_LOCATION=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:6380/1
    DJANGO_CACHE_TIMEOUT=1296000
    DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient
    USE_CELERY=True
    CELERY_BROKER=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:6380/2
    CELERY_BACKEND=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:6380/2
    CELERY_WORKER_CONCURRENCY=2
    ALLOW_REGISTRATION=False
    ALLOW_GUEST_USERS=False
    ALLOW_UPLOAD_VIDEOS=False
    AUTH_PROXY_HEADER=HTTP_REMOTE_USER
    AUTH_PROXY_TRUSTED_IPS=10.10.30.110
    AUTH_PROXY_CREATE_UNKNOWN_USER=True
    NUMBER_OF_PROXIES=1
    WGER_USE_GUNICORN=True
    DJANGO_DEBUG=False
    LOG_LEVEL_PYTHON=INFO
    EXPOSE_PROMETHEUS_METRICS=False
  '';
```

#### 3. Add firewall port

In `networking.firewall.allowedTCPPorts`, add:

```nix
      8000    # wger
```

#### 4. Add OCI containers

In `virtualisation.oci-containers.containers`, add:

```nix
    # wger — fitness and workout tracker (web / gunicorn)
    wger = {
      image = "docker.io/wger/server:latest";
      environmentFiles = [ config.sops.templates."wger-env".path ];
      volumes = [
        "/var/lib/homelab/wger/static:/home/wger/static"
        "/var/lib/homelab/wger/media:/home/wger/media"
      ];
      ports = [ "8000:8000" ];
      extraOptions = [ "--network=iowa" ];
    };

    # wger — Celery async worker
    wger-worker = {
      image = "docker.io/wger/server:latest";
      cmd = [ "/start-worker" ];
      environmentFiles = [ config.sops.templates."wger-env".path ];
      volumes = [
        "/var/lib/homelab/wger/static:/home/wger/static"
        "/var/lib/homelab/wger/media:/home/wger/media"
      ];
      extraOptions = [ "--network=iowa" ];
    };

    # wger — Celery beat periodic scheduler
    wger-beat = {
      image = "docker.io/wger/server:latest";
      cmd = [ "/start-beat" ];
      environmentFiles = [ config.sops.templates."wger-env".path ];
      volumes = [
        "/var/lib/homelab/wger/static:/home/wger/static"
        "/var/lib/homelab/wger/media:/home/wger/media"
        "/var/lib/homelab/wger/beat:/home/wger/beat"
      ];
      extraOptions = [ "--network=iowa" ];
    };
```

#### 5. Add persistent data directories

In `systemd.tmpfiles.rules`, add:

```nix
    "d /var/lib/homelab/wger 0755 root root -"
    "d /var/lib/homelab/wger/static 0755 root root -"
    "d /var/lib/homelab/wger/media 0755 root root -"
    "d /var/lib/homelab/wger/beat 0755 root root -"
```

---

### File: `secrets/sugar.yaml` (REMINDER)

Add these secrets (encrypt with `sops secrets/sugar.yaml`):

- `wger_secret_key: <long-random-string>` — Django SECRET_KEY (generate with `python3 -c "import secrets; print(secrets.token_urlsafe(50))"`)
- `wger_signing_key: <long-random-string>` — JWT SIGNING_KEY (generate same way)
- `wger_db_pass: <postgres-wger-user-password>` — Password for the `wger` PostgreSQL user

---

### File: `hosts/psychosocial/default.nix` (EDIT) — Caddy route

In the `*.pytt.io` block, under the `# --- sugar (staging: 10.10.30.111) ---` section, add:

```nix
        @wger host wger.pytt.io
        handle @wger {
          import authelia
          reverse_proxy 10.10.30.111:8000
        }
```

---

### Manual Steps

1. **Create PostgreSQL database and user on TrueNAS (10.10.10.20)**

   Connect to the TrueNAS PostgreSQL instance and run:
   ```sql
   CREATE USER wger WITH PASSWORD '<wger_db_pass>';
   CREATE DATABASE wger OWNER wger;
   GRANT ALL PRIVILEGES ON DATABASE wger TO wger;
   ```

2. **First deploy — verify migrations ran**

   After `colmena apply --on sugar`, check:
   ```bash
   docker logs wger 2>&1 | grep -i migrat
   ```
   Migrations should complete automatically on first startup.

3. **Promote first SSO user to superuser (optional)**

   After logging in once via Authelia (which auto-creates the user), promote via Django shell:
   ```bash
   docker exec -it wger python manage.py shell -c "
   from django.contrib.auth import get_user_model
   User = get_user_model()
   u = User.objects.get(username='<your-authelia-username>')
   u.is_staff = True
   u.is_superuser = True
   u.save()
   "
   ```

4. **Authelia access_control** — wger uses Authelia forward auth via `import authelia` in Caddy. The existing `{ domain = [ "*.pytt.io" ]; policy = "one_factor"; }` rule in `hosts/psychosocial/default.nix` already covers `wger.pytt.io`, so no Authelia rule change is needed.

---

### Verification

- `nix flake check` passes
- `colmena apply --on sugar` deploys successfully
- `systemctl status docker-wger` shows active on sugar
- `systemctl status docker-wger-worker` shows active on sugar
- `systemctl status docker-wger-beat` shows active on sugar
- `docker logs wger` shows gunicorn started without errors and migrations completed
- Web UI accessible at `https://wger.pytt.io` (redirects through Authelia login)
- Caddy on psychosocial: `curl -I https://wger.pytt.io` returns 302 → Authelia login

---

## Pre-deploy Checklist

- [ ] **Host config** — wger containers, env template, and secrets added to `hosts/sugar/default.nix`
- [ ] **Firewall** — port 8000 added to `networking.firewall.allowedTCPPorts` in `hosts/sugar/default.nix`
- [ ] **Secrets** — `wger_secret_key`, `wger_signing_key`, `wger_db_pass` added to `secrets/sugar.yaml` via SOPS
- [ ] **Caddy route** — `@wger` handle block added to `hosts/psychosocial/default.nix`
- [ ] **Database** — `wger` PostgreSQL user and database created on TrueNAS
- [ ] **Redis** — No new Redis service needed; uses existing `norish` instance (port 6380) on DB indices 1 and 2
- [ ] **Data dirs** — tmpfiles rules added for `/var/lib/homelab/wger/{static,media,beat}`
- [ ] **Auth** — Authelia forward auth via `import authelia` in Caddy; `AUTH_PROXY_HEADER=HTTP_REMOTE_USER` set in env
- [ ] **flake check** — `nix flake check` passes before deploy
