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
    # Disable DynamicUser so we can manage data/permissions
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
