{
  config,
  lib,
  ...
}:
let
  cfg = config.server.netbootxyz;
in
{
  options.server.netbootxyz = {
    enable = lib.mkEnableOption "netboot.xyz PXE boot server (Docker)";
    webPort = lib.mkOption {
      type = lib.types.port;
      default = 3003;
      description = "Port for the netboot.xyz web UI";
    };
    assetsPort = lib.mkOption {
      type = lib.types.port;
      default = 8086;
      description = "Port for the netboot.xyz assets HTTP server";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.netbootxyz = {
      image = "ghcr.io/netbootxyz/netbootxyz";
      volumes = [
        "/var/lib/homelab/netbootxyz/config:/config"
        "/var/lib/homelab/netbootxyz/assets:/assets"
      ];
      ports = [
        "${toString cfg.webPort}:3000" # web UI
        "69:69/udp" # TFTP
        "${toString cfg.assetsPort}:8080" # assets HTTP server
      ];
      extraOptions = [ "--network=iowa" ];
    };

    systemd.services.docker-netbootxyz = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall = {
      allowedTCPPorts = [
        cfg.webPort
        cfg.assetsPort
      ];
      allowedUDPPorts = [ 69 ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/homelab/netbootxyz 0755 root root -"
      "d /var/lib/homelab/netbootxyz/config 0755 root root -"
      "d /var/lib/homelab/netbootxyz/assets 0755 root root -"
    ];
  };
}
