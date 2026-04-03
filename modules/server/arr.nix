{
  config,
  lib,
  ...
}:
let
  cfg = config.server.arr;
in
{
  options.server.arr = {
    enable = lib.mkEnableOption "ARR media stack (sonarr, radarr, prowlarr, lidarr)";
    sonarrPort = lib.mkOption {
      type = lib.types.port;
      default = 8989;
      description = "Port for Sonarr";
    };
    radarrPort = lib.mkOption {
      type = lib.types.port;
      default = 7878;
      description = "Port for Radarr";
    };
    prowlarrPort = lib.mkOption {
      type = lib.types.port;
      default = 9696;
      description = "Port for Prowlarr";
    };
    lidarrPort = lib.mkOption {
      type = lib.types.port;
      default = 8686;
      description = "Port for Lidarr";
    };
  };

  config = lib.mkIf cfg.enable {
    # Shared media group for filesystem access across all services
    users.groups.media.gid = 1000;

    # Sops secrets for exportarr API keys
    sops.secrets.sonarr_api_key = { };
    sops.secrets.radarr_api_key = { };
    sops.secrets.lidarr_api_key = { };
    sops.secrets.prowlarr_api_key = { };

    # Prometheus exporters for arr services
    services.prometheus.exporters.exportarr-sonarr = {
      enable = true;
      port = 9707;
      url = "http://127.0.0.1:${toString cfg.sonarrPort}";
      apiKeyFile = config.sops.secrets.sonarr_api_key.path;
      openFirewall = true;
    };
    services.prometheus.exporters.exportarr-radarr = {
      enable = true;
      port = 9708;
      url = "http://127.0.0.1:${toString cfg.radarrPort}";
      apiKeyFile = config.sops.secrets.radarr_api_key.path;
      openFirewall = true;
    };
    services.prometheus.exporters.exportarr-lidarr = {
      enable = true;
      port = 9709;
      url = "http://127.0.0.1:${toString cfg.lidarrPort}";
      apiKeyFile = config.sops.secrets.lidarr_api_key.path;
      openFirewall = true;
    };
    services.prometheus.exporters.exportarr-prowlarr = {
      enable = true;
      port = 9710;
      url = "http://127.0.0.1:${toString cfg.prowlarrPort}";
      apiKeyFile = config.sops.secrets.prowlarr_api_key.path;
      openFirewall = true;
    };

    systemd.services.sonarr = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
    systemd.services.radarr = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
    systemd.services.prowlarr = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
    systemd.services.lidarr = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    # --- Sonarr ---
    services.sonarr = {
      enable = true;
      openFirewall = true;
      group = "media";
      settings = {
        server.port = cfg.sonarrPort;
        log.analyticsEnabled = false;
        update.mechanism = "external";
      };
    };

    # --- Radarr ---
    services.radarr = {
      enable = true;
      openFirewall = true;
      group = "media";
      settings = {
        server.port = cfg.radarrPort;
        log.analyticsEnabled = false;
        update.mechanism = "external";
      };
    };

    # --- Prowlarr ---
    services.prowlarr = {
      enable = true;
      openFirewall = true;
      settings = {
        server.port = cfg.prowlarrPort;
        log.analyticsEnabled = false;
        update.mechanism = "external";
      };
    };
    # Disable DynamicUser so we can manage data/permissions with the shared media group.
    # mkForce needed here to override NixOS prowlarr module's hardcoded DynamicUser = true.
    users.users.prowlarr = {
      isSystemUser = true;
      group = "media";
    };
    systemd.services.prowlarr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "prowlarr";
      Group = "media";
    };

    # --- Lidarr ---
    services.lidarr = {
      enable = true;
      openFirewall = true;
      group = "media";
      settings = {
        server.port = cfg.lidarrPort;
        log.analyticsEnabled = false;
        update.mechanism = "external";
      };
    };
  };
}
