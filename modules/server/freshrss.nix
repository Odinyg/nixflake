{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.freshrss;

  af-readability = pkgs.freshrss-extensions.buildFreshRssExtension {
    FreshRssExtUniqueId = "Af_Readability";
    pname = "af-readability";
    version = "unstable-2026-03-12";
    src = pkgs.fetchFromGitHub {
      owner = "Niehztog";
      repo = "freshrss-af-readability";
      rev = "c0867be4692fa7de3e3d4bb0b88ec5d2a2a7def1";
      hash = "sha256-y9+7kkzNRmOHNFVhv004ZVVnhoeVEvbDjLE2AGlztTE=";
    };
    meta = {
      description = "FreshRSS extension to fetch full article content using Readability";
      homepage = "https://github.com/Niehztog/freshrss-af-readability";
      license = lib.licenses.agpl3Only;
    };
  };
in
{
  options.server.freshrss = {
    enable = lib.mkEnableOption "FreshRSS RSS aggregator";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8282;
      description = "Port for the FreshRSS web interface (nginx listener)";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "freshrss.pytt.io";
      description = "Public domain for FreshRSS";
    };
    defaultUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Default admin username";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.freshrss_admin_password = {
      owner = "freshrss";
    };

    services.freshrss = {
      enable = true;
      baseUrl = "https://${cfg.domain}";
      defaultUser = cfg.defaultUser;
      passwordFile = config.sops.secrets.freshrss_admin_password.path;
      authType = "none";
      language = "en";

      api.enable = true;

      database.type = "sqlite";

      extensions = [ af-readability ];

      virtualHost = cfg.domain;
    };

    # Override nginx to listen on cfg.port instead of 80 (Nextcloud already uses 80)
    services.nginx.virtualHosts.${cfg.domain} = {
      listen = [
        {
          addr = "0.0.0.0";
          port = cfg.port;
        }
      ];
    };

    systemd.services.phpfpm-freshrss = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
