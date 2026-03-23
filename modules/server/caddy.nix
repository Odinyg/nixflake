{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.caddy;
in
{
  options.server.caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy with Cloudflare DNS";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.caddy_cloudflare_api_token = { };

    sops.templates."caddy-env".content = ''
      CLOUDFLARE_API_TOKEN=${config.sops.placeholder.caddy_cloudflare_api_token}
    '';

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
        hash = "sha256-o0zYCp3h7E0L1cgmJwNtGNgzhmZk5BAVoWQA+eL+zqc=";
      };
      globalConfig = ''
        admin 0.0.0.0:2019
        servers {
          metrics
        }
      '';
    };

    systemd.services.caddy = {
      serviceConfig.EnvironmentFile = config.sops.templates."caddy-env".path;
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [
      80 # HTTP (ACME + redirect)
      443 # HTTPS
    ];
  };
}
