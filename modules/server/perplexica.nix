{
  config,
  lib,
  ...
}:
let
  cfg = config.server.perplexica;
in
{
  options.server.perplexica = {
    enable = lib.mkEnableOption "Perplexica AI search engine (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
      description = "Port for the Perplexica web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.perplexica = {
      image = "itzcrazykns1337/perplexica:slim-latest";
      environment = {
        SEARXNG_API_URL = "http://127.0.0.1:8888";
      };
      volumes = [
        "/var/lib/homelab/perplexica/data:/home/perplexica/data"
        "/var/lib/homelab/perplexica/uploads:/home/perplexica/uploads"
      ];
      ports = [ "${toString cfg.port}:3000" ];
      extraOptions = [ "--network=iowa" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d /var/lib/homelab/perplexica 0755 root root -"
      "d /var/lib/homelab/perplexica/data 0755 root root -"
      "d /var/lib/homelab/perplexica/uploads 0755 root root -"
    ];
  };
}
