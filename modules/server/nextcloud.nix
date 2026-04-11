{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.nextcloud;
in
{
  options.server.nextcloud = {
    enable = lib.mkEnableOption "Nextcloud file storage";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "nextcloud.pytt.io";
      description = "Hostname for Nextcloud";
    };
    dbHost = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.20:5432";
      description = "PostgreSQL host and port for Nextcloud";
    };
    trustedProxies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.10.30.110" ];
      description = "List of trusted proxy addresses";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.nextcloud_admin_pass = {
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0440";
    };
    sops.secrets.postgresql_nextcloud_password = {
      owner = "nextcloud";
    };
    sops.secrets.redis_pass = { };

    sops.templates."nextcloud-secret" = {
      content = builtins.toJSON {
        redis.password = config.sops.placeholder.redis_pass;
      };
      owner = "nextcloud";
    };

    # Redis for Nextcloud caching
    services.redis.servers.nextcloud = {
      enable = true;
      port = 6379;
      bind = "127.0.0.1";
      requirePassFile = config.sops.secrets.redis_pass.path;
    };

    services.nextcloud = {
      enable = true;
      hostName = cfg.domain;
      # Keep Nextcloud pinned explicitly during the 32 -> 33 upgrade window.
      # Nextcloud upgrades must be done one major version at a time.
      package = pkgs.nextcloud32;
      maxUploadSize = "1G";

      config = {
        adminuser = "none";
        adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
        dbtype = "pgsql";
        dbhost = cfg.dbHost;
        dbname = "nextcloud";
        dbuser = "nextcloud";
        dbpassFile = config.sops.secrets.postgresql_nextcloud_password.path;
      };

      settings = {
        overwriteprotocol = "https";
        trusted_proxies = cfg.trustedProxies;
        default_phone_region = "NO";
        log_type = "file";
      };

      secretFile = config.sops.templates."nextcloud-secret".path;
      caching.redis = true;
    };

    systemd.services.nextcloud-setup = {
      after = [ "redis-nextcloud.service" ];
      requires = [ "redis-nextcloud.service" ];
    };


    systemd.services.phpfpm-nextcloud = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    # Prometheus nextcloud exporter
    services.prometheus.exporters.nextcloud = {
      enable = true;
      port = 9205;
      url = "http://localhost/ocs/v2.php/apps/serverinfo/api/v1/info";
      username = "none";
      passwordFile = config.sops.secrets.nextcloud_admin_pass.path;
      openFirewall = true;
    };

    users.users.nextcloud-exporter.extraGroups = [ "nextcloud" ];

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
