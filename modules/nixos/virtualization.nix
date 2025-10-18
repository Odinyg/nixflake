{ lib, config, pkgs, ... }: {
  options = {
    virtualization = {
      enable = lib.mkEnableOption {
        description = "Enable virtualization and container support";
        default = false;
      };

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

      remoteAccess = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable remote access tools (Remmina, etc.)";
        };
      };
    };
  };

  config = lib.mkIf config.virtualization.enable {
    # Docker configuration
    virtualisation.docker = lib.mkIf config.virtualization.docker.enable {
      enable = true;
      enableOnBoot = true;
      rootless = lib.mkIf config.virtualization.docker.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };

    virtualisation.podman = lib.mkIf config.virtualization.podman.enable {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    virtualisation.libvirtd = lib.mkIf config.virtualization.qemu.enable {
      enable = true;
      qemu = {
        runAsRoot = true;
        swtpm.enable = true;
      };
      onBoot = "start";
      onShutdown = "shutdown";
    };

    virtualisation.spiceUSBRedirection.enable =
      lib.mkIf config.virtualization.qemu.spice true;
    services.spice-vdagentd.enable =
      lib.mkIf config.virtualization.qemu.spice true;

    programs.virt-manager.enable =
      lib.mkIf config.virtualization.qemu.virt-manager true;

    virtualisation.virtualbox.host =
      lib.mkIf config.virtualization.virtualbox.enable {
        enable = true;
        enableExtensionPack = true;
      };

    virtualisation.waydroid.enable =
      lib.mkIf config.virtualization.waydroid.enable true;

    users.users.${config.user}.extraGroups = lib.flatten [
      (lib.optional config.virtualization.docker.enable "docker")
      (lib.optional config.virtualization.qemu.enable "libvirtd")
      (lib.optional config.virtualization.qemu.enable "kvm")
      (lib.optional config.virtualization.virtualbox.enable "vboxusers")
    ];

    environment.systemPackages = with pkgs;
      lib.flatten [
        (lib.optionals config.virtualization.docker.enable [
          docker
          docker-compose
        ])

        (lib.optionals config.virtualization.podman.enable [
          podman-compose
          buildah
          skopeo
        ])

        (lib.optionals config.virtualization.qemu.enable [
          virtiofsd
          OVMF
          swtpm
        ])

        (lib.optionals config.virtualization.remoteAccess.enable [
          remmina
          freerdp3
        ])
      ];
  };
}
