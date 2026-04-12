{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.virtualization;
in
{
  options = {
    virtualization = {
      enable = lib.mkEnableOption "virtualization and container support";

      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Docker container runtime";
        };

        rootless = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable rootless Docker";
        };
      };

      podman = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Podman container runtime";
        };
      };

      qemu = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable QEMU/KVM virtualization";
        };

        virt-manager = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable virt-manager GUI";
        };

        spice = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable SPICE protocol support";
        };
      };

      virtualbox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable VirtualBox";
        };
      };

      waydroid = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Waydroid (Android containers)";
        };
      };

    };
  };

  config = lib.mkIf cfg.enable {
    # Docker configuration
    virtualisation.docker = lib.mkIf cfg.docker.enable {
      enable = true;
      enableOnBoot = true;
      rootless = lib.mkIf cfg.docker.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };

    virtualisation.podman = lib.mkIf cfg.podman.enable {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    virtualisation.libvirtd = lib.mkIf cfg.qemu.enable {
      enable = true;
      package = pkgs.libvirt;
      qemu = {
        package = pkgs.qemu;
        runAsRoot = true;
        swtpm.enable = true;
      };
      onBoot = "start";
      onShutdown = "shutdown";
    };

    virtualisation.spiceUSBRedirection.enable = lib.mkIf cfg.qemu.spice true;
    services.spice-vdagentd.enable = lib.mkIf cfg.qemu.spice true;

    programs.virt-manager = lib.mkIf cfg.qemu.virt-manager {
      enable = true;
      package = pkgs.virt-manager;
    };

    virtualisation.virtualbox.host = lib.mkIf cfg.virtualbox.enable {
      enable = true;
      enableExtensionPack = true;
    };

    virtualisation.waydroid.enable = lib.mkIf cfg.waydroid.enable true;

    users.users.${config.user}.extraGroups = lib.flatten [
      (lib.optional cfg.docker.enable "docker")
      (lib.optional cfg.qemu.enable "libvirtd")
      (lib.optional cfg.qemu.enable "kvm")
      (lib.optional cfg.virtualbox.enable "vboxusers")
    ];

    environment.systemPackages =
      with pkgs;
      lib.flatten [
        (lib.optionals cfg.docker.enable [
          docker
          docker-compose
        ])

        (lib.optionals cfg.podman.enable [
          podman-compose
          buildah
          skopeo
        ])

        (lib.optionals cfg.qemu.enable [
          virtiofsd
          swtpm
        ])
      ];
  };
}
