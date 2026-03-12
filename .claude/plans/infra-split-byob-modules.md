# Infra: Split byob into reusable server modules

**Status:** plan-complete
**Date:** 2026-03-12
**Affected components:** `hosts/byob/default.nix`, `modules/server/`

## Goal

Extract ARR stack services from byob's host config into reusable server modules so any host (prod, staging) can enable them without duplicating config.

## Current State

All services are inline in `hosts/byob/default.nix` — ~190 lines of service config that can't be reused. Server modules live in `modules/server/` and follow the `cfg.enable` pattern (see `nfs.nix`, `monitoring.nix`).

## Approach

Split into 4 modules under `modules/server/`:

| Module | What it contains | Why separate |
|--------|-----------------|--------------|
| `arr.nix` | media group + sonarr + radarr + prowlarr + lidarr | These 4 always deploy together |
| `nzbget.nix` | NZBGet + unrar/7za/certs + download dirs | Independent download client |
| `transmission.nix` | Transmission + mount dependency + dirs | Independent download client |
| `seerr.nix` | Docker + Seerr container | Optional media requests |

**What stays in the host config:** hostname, networking/IP, overlays (pkgs-unstable), NAS mount options, downloads disk mount, seerr firewall port, stateVersion. These are host-specific.

**Design decisions:**
- Each module gets a top-level `server.<name>.enable` option (matches existing `server.enable` namespace)
- `server.arr.enable` creates the `media` group and enables all 4 ARR services — no individual toggles (they always go together)
- Download paths use `lib.mkDefault` so hosts can override
- The unstable overlay stays in the host — it's a packaging concern, not a service concern

---

## Implementation Plan

### File: `modules/server/arr.nix` (CREATE)
```nix
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
  };

  config = lib.mkIf cfg.enable {
    # Shared media group for filesystem access across all services
    users.groups.media.gid = 1000;

    # --- Sonarr ---
    services.sonarr = {
      enable = true;
      openFirewall = true;
      group = "media";
      settings = {
        server.port = 8989;
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
        server.port = 7878;
        log.analyticsEnabled = false;
        update.mechanism = "external";
      };
    };

    # --- Prowlarr ---
    services.prowlarr = {
      enable = true;
      openFirewall = true;
      settings = {
        server.port = 9696;
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
        server.port = 8686;
        log.analyticsEnabled = false;
        update.mechanism = "external";
      };
    };
  };
}
```

### File: `modules/server/nzbget.nix` (CREATE)
```nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.nzbget;
in
{
  options.server.nzbget = {
    enable = lib.mkEnableOption "NZBGet usenet download client";
    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/downloads";
      description = "Base download directory";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nzbget = {
      enable = true;
      group = "media";
      settings = {
        MainDir = cfg.downloadDir;
        DestDir = "${cfg.downloadDir}/complete";
        InterDir = "${cfg.downloadDir}/incomplete";
        NzbDir = "${cfg.downloadDir}/nzb";
        QueueDir = "${cfg.downloadDir}/queue";
        TempDir = "${cfg.downloadDir}/tmp";
        ScriptDir = "${cfg.downloadDir}/scripts";
        UnrarCmd = "${pkgs.unrar}/bin/unrar";
        SevenZipCmd = "${pkgs.p7zip}/bin/7za";
        CertStore = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
    };

    networking.firewall.allowedTCPPorts = [ 6789 ];

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir}/nzb 0775 nzbget media -"
      "d ${cfg.downloadDir}/queue 0775 nzbget media -"
      "d ${cfg.downloadDir}/tmp 0775 nzbget media -"
      "d ${cfg.downloadDir}/scripts 0775 nzbget media -"
    ];
  };
}
```

### File: `modules/server/transmission.nix` (CREATE)
```nix
{
  config,
  lib,
  ...
}:
let
  cfg = config.server.transmission;
in
{
  options.server.transmission = {
    enable = lib.mkEnableOption "Transmission BitTorrent client";
    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/downloads";
      description = "Base download directory";
    };
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;
      group = "media";
      openRPCPort = true;
      settings = {
        download-dir = "${cfg.downloadDir}/complete";
        incomplete-dir = "${cfg.downloadDir}/incomplete";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
      };
    };

    systemd.services.transmission = {
      after = [ "mnt-downloads.mount" ];
      requires = [ "mnt-downloads.mount" ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir}/complete 0775 transmission media -"
      "d ${cfg.downloadDir}/incomplete 0775 transmission media -"
    ];
  };
}
```

### File: `modules/server/seerr.nix` (CREATE)
```nix
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
      ports = [ "5055:5055" ];
    };

    networking.firewall.allowedTCPPorts = [ 5055 ];
  };
}
```

### File: `modules/server/default.nix` (EDIT)
Add imports for the 4 new modules.

Old:
```nix
  imports = [
    ./nfs.nix
    ./monitoring.nix
    ./disko.nix
  ];
```
New:
```nix
  imports = [
    ./nfs.nix
    ./monitoring.nix
    ./disko.nix
    ./arr.nix
    ./nzbget.nix
    ./transmission.nix
    ./seerr.nix
  ];
```

### File: `hosts/byob/default.nix` (EDIT)
Replace all inline service config with module enables. Becomes ~50 lines.

New content:
```nix
{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  # Use unstable packages for ARR stack (Docker :latest tracks unstable)
  nixpkgs.overlays = [
    (final: prev: {
      sonarr = pkgs-unstable.sonarr;
      radarr = pkgs-unstable.radarr;
      prowlarr = pkgs-unstable.prowlarr;
      lidarr = pkgs-unstable.lidarr;
      nzbget = pkgs-unstable.nzbget;
      overseerr = pkgs-unstable.overseerr;
    })
  ];

  networking.hostName = "byob";

  # Static IP — staging (change to 10.10.50.10 after cutover)
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.50.110";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.10.50.1";
    nameservers = [
      "10.10.10.1"
      "1.1.1.1"
    ];
  };

  # sops.defaultSopsFile = ../../secrets/byob.yaml; # TODO: enable after encrypting secrets

  # NAS media mount — remove noauto to activate
  fileSystems."/mnt/nas/media".options = lib.mkForce [
    "defaults"
    "x-systemd.automount"
    "x-systemd.idle-timeout=600"
    "_netdev"
  ];

  # Local downloads disk (second VirtIO disk)
  fileSystems."/mnt/downloads" = {
    device = "/dev/vdb";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  # --- Services ---
  server.arr.enable = true;
  server.nzbget.enable = true;
  server.transmission.enable = true;
  server.seerr.enable = true;

  # Media dirs on NAS
  systemd.tmpfiles.rules = [
    "d /mnt/nas/media/tv 0775 root media -"
  ];

  system.stateVersion = "25.05";
}
```

### Verification
- `nix fmt` — format all new files
- `colmena eval` or `colmena build` on byob — should produce identical config
- Optionally `nix eval .#nixosConfigurations.byob.config.server.arr.enable` to confirm options resolve
