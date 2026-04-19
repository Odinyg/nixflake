{
  config,
  lib,
  ...
}:
let
  cfg = config.hosted-services.windows-vm;
in
{
  options.hosted-services.windows-vm = {
    enable = lib.mkEnableOption "Windows VM via dockur/windows (KVM-accelerated, web viewer on port 8006)";

    version = lib.mkOption {
      type = lib.types.str;
      default = "11";
      description = "Windows edition — '11' (Pro), '11l' (LTSC), '11e' (Enterprise), '10', etc.";
    };

    webPort = lib.mkOption {
      type = lib.types.port;
      default = 8006;
      description = "Web viewer (noVNC) port";
    };

    rdpPort = lib.mkOption {
      type = lib.types.port;
      default = 3389;
      description = "RDP port";
    };

    storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/windows-vm";
      description = "Host path for Windows disk image and state";
    };

    ram = lib.mkOption {
      type = lib.types.str;
      default = "8G";
      description = "RAM allocated to the VM";
    };

    cpu = lib.mkOption {
      type = lib.types.str;
      default = "4";
      description = "Number of CPU cores allocated to the VM";
    };

    disk = lib.mkOption {
      type = lib.types.str;
      default = "64G";
      description = "Virtual disk size";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.windows-vm = {
      image = "dockurr/windows";
      environment = {
        VERSION = cfg.version;
        RAM_SIZE = cfg.ram;
        CPU_CORES = cfg.cpu;
        DISK_SIZE = cfg.disk;
      };
      ports = [
        "${toString cfg.webPort}:8006"
        "${toString cfg.rdpPort}:3389/tcp"
        "${toString cfg.rdpPort}:3389/udp"
      ];
      volumes = [ "${cfg.storagePath}:/storage" ];
      extraOptions = [
        "--device=/dev/kvm"
        "--device=/dev/net/tun"
        "--cap-add=NET_ADMIN"
        "--stop-timeout=120"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.storagePath} 0755 root root -"
    ];

    networking.firewall.allowedTCPPorts = [
      cfg.webPort
      cfg.rdpPort
    ];
    networking.firewall.allowedUDPPorts = [
      cfg.rdpPort
    ];
  };
}
