{
  config,
  lib,
  ...
}:
let
  cfg = config.server.wger;
in
{
  options.server.wger = {
    enable = lib.mkEnableOption "wger workout manager (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port for the wger web interface";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for wger";
    };
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "PostgreSQL host for wger";
    };
    redisPort = lib.mkOption {
      type = lib.types.port;
      default = 6380;
      description = "Redis port (reuses norish Redis instance with separate DB indices)";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.postgresql_wger_password = { };
    sops.secrets.wger_secret_key = { };
    sops.secrets.wger_signing_key = { };
    sops.secrets.redis_pass = { };

    sops.templates."wger-env".content = ''
      SECRET_KEY=${config.sops.placeholder.wger_secret_key}
      SIGNING_KEY=${config.sops.placeholder.wger_signing_key}
      SITE_URL=https://wger.${cfg.domain}
      CSRF_TRUSTED_ORIGINS=https://wger.${cfg.domain}
      X_FORWARDED_PROTO_HEADER_SET=True
      TIME_ZONE=Europe/Oslo
      TZ=Europe/Oslo
      DJANGO_DB_ENGINE=django.db.backends.postgresql
      DJANGO_DB_DATABASE=wger
      DJANGO_DB_USER=wger
      DJANGO_DB_PASSWORD=${config.sops.placeholder.postgresql_wger_password}
      DJANGO_DB_HOST=${cfg.dbHost}
      DJANGO_DB_PORT=5432
      DJANGO_PERFORM_MIGRATIONS=True
      DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
      DJANGO_CACHE_LOCATION=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:${toString cfg.redisPort}/1
      DJANGO_CACHE_TIMEOUT=1296000
      DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient
      USE_CELERY=True
      CELERY_BROKER=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:${toString cfg.redisPort}/2
      CELERY_BACKEND=redis://:${config.sops.placeholder.redis_pass}@127.0.0.1:${toString cfg.redisPort}/2
      CELERY_WORKER_CONCURRENCY=2
      ALLOW_REGISTRATION=False
      ALLOW_GUEST_USERS=False
      ALLOW_UPLOAD_VIDEOS=False
      AUTH_PROXY_HEADER=HTTP_REMOTE_USER
      AUTH_PROXY_CREATE_UNKNOWN_USER=True
      NUMBER_OF_PROXIES=1
      WGER_USE_GUNICORN=True
      DJANGO_DEBUG=False
      LOG_LEVEL_PYTHON=INFO
      EXPOSE_PROMETHEUS_METRICS=False
    '';

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.wger = {
      image = "docker.io/wger/server:latest";
      environmentFiles = [ config.sops.templates."wger-env".path ];
      volumes = [
        "/var/lib/homelab/wger/static:/home/wger/static"
        "/var/lib/homelab/wger/media:/home/wger/media"
      ];
      ports = [ "${toString cfg.port}:8000" ];
      extraOptions = [ "--network=iowa" ];
    };

    virtualisation.oci-containers.containers.wger-worker = {
      image = "docker.io/wger/server:latest";
      cmd = [ "/start-worker" ];
      environmentFiles = [ config.sops.templates."wger-env".path ];
      volumes = [
        "/var/lib/homelab/wger/static:/home/wger/static"
        "/var/lib/homelab/wger/media:/home/wger/media"
      ];
      extraOptions = [ "--network=iowa" ];
    };

    virtualisation.oci-containers.containers.wger-beat = {
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

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d /var/lib/homelab/wger 0755 root root -"
      "d /var/lib/homelab/wger/static 0755 root root -"
      "d /var/lib/homelab/wger/media 0755 root root -"
      "d /var/lib/homelab/wger/beat 0755 root root -"
    ];
  };
}
