{
  config,
  lib,
  ...
}:
let
  cfg = config.server.seerr;
in
{
  options.server.seerr = {
    enable = lib.mkEnableOption "Seerr media request manager (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 5055;
      description = "Port for the Seerr web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.seerr = {
      image = "seerr/seerr:latest";
      environment = {
        TZ = "Europe/Oslo";
      };
      volumes = [ "/var/lib/homelab/seerr:/app/config" ];
      ports = [ "${toString cfg.port}:5055" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
