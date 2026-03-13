{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.searxng;
in
{
  options.server.searxng = {
    enable = lib.mkEnableOption "SearXNG privacy search engine";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Port for the SearXNG web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.searxng_secret = { };

    sops.templates."searxng-env".content = ''
      SEARXNG_SECRET=${config.sops.placeholder.searxng_secret}
    '';

    services.searx = {
      enable = true;
      package = pkgs.searxng;
      redisCreateLocally = true;
      environmentFile = config.sops.templates."searxng-env".path;
      settings = {
        server = {
          port = cfg.port;
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

    systemd.services.searx = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    # searx-init needs sops secrets decrypted before it can load the env file
    systemd.services.searx-init = {
      after = [ "sops-nix.service" ];
      requires = [ "sops-nix.service" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
