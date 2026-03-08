# Infra: Migrate Homelab from Docker Compose to NixOS

**Status:** in-progress (byob config written — native services, needs VM + data migration)
**Date:** 2026-03-06
**Affected components:** psychosocial, byob, sugar, pulse (sulfur stays Ubuntu)

## Goal

Migrate the homelab from Ubuntu+Docker Compose to NixOS with native service modules where available, falling back to OCI containers for unsupported services. Single flake (flake-parts), per-host configs, sops-nix for secrets, Colmena for deployment.

## Current State

- 5 Docker Compose servers on Ubuntu (psychosocial, byob, sugar, pulse, sulfur)
- 25 services across the fleet, managed via compose YAML + SOPS-encrypted `.env` files
- Deploy workflow: git push → GitHub Actions CI → webhook → `git pull && compose up`
- Secrets: SOPS + age, 3 tiers (low/medium/critical), bash script decrypts to `/etc/homelab/.env`
- Age keys at `/etc/homelab/sops/keys.txt` on each VM

## Staging IP Strategy

New NixOS VMs run alongside existing Ubuntu VMs during migration. Same VLANs, different IPs:

| Host | Current (Ubuntu) | Staging (NixOS) | VLAN |
|------|-------------------|-----------------|------|
| psychosocial | 10.10.30.10 | 10.10.30.110 | Homelab |
| byob | 10.10.50.10 | 10.10.50.110 | Media/ARR |
| sugar | 10.10.30.11 | 10.10.30.111 | Homelab |
| pulse | 10.10.30.12 | 10.10.30.112 | Homelab |
| sulfur | 10.10.30.14 | — (stays Ubuntu) | Homelab |

**Cutover process per host:**
1. Deploy NixOS VM with staging IP, verify everything works
2. Update Caddy on psychosocial to point at staging IP for that host's services
3. Verify end-to-end (reverse proxy → new VM → services)
4. When confident: shut down old Ubuntu VM, reassign its IP to the NixOS VM
5. Keep old VM disk image on Proxmox as rollback for 2 weeks

**psychosocial goes last** since it's the reverse proxy — it can proxy to staging IPs during migration of other hosts, then itself gets migrated with the IP swap.

## Research

### NixOS Module Availability (19 of 25 services)

| Service | Module | Maturity | Notable Gaps |
|---------|--------|----------|--------------|
| **psychosocial** | | | |
| Caddy | `services.caddy` | Well-maintained | `withPlugins` supports Cloudflare DNS natively (NixOS 25.05+) |
| Authelia | `services.authelia.instances.<name>` | Well-maintained | Secrets must use `_FILE` suffix or `secrets` option |
| Homepage | `services.homepage-dashboard` | Well-maintained | `HOMEPAGE_VAR_*` env substitution needs rework |
| Webhook | `services.webhook` | Well-maintained | Minimal gaps |
| Alloy | `services.alloy` | Basic | Config file managed externally (HCL-like format) |
| **byob** | | | |
| Sonarr | `services.sonarr` | Well-maintained | No container isolation; media path perms manual |
| Radarr | `services.radarr` | Well-maintained | Same as Sonarr |
| Prowlarr | `services.prowlarr` | Well-maintained | Same |
| Lidarr | `services.lidarr` | Well-maintained | Same |
| NZBGet | `services.nzbget` | Basic | Config via CLI flags only; upstream maintenance concerns |
| Transmission | `services.transmission` | Well-maintained | VPN routing needs network-level solution (not sidecar) |
| Overseerr | `services.overseerr` | Basic | Only 4 options; transitioning to "Seerr" |
| **sugar** | | | |
| n8n | `services.n8n` | Basic | No DB management; community nodes unsupported |
| SearXNG | `services.searx` (+ `pkgs.searxng`) | Well-maintained | Good fit — declarative settings, local Redis |
| Perplexica | **None** | — | OCI container required |
| Nextcloud | `services.nextcloud` | Well-maintained | Excellent module — better than Docker for NC |
| netboot.xyz | **None** | — | No server module; OCI container required |
| Norish | **None** | — | Niche app; OCI container required |
| Myrlin | **None** | — | Custom app; OCI container or custom derivation |
| Paseo | **None** | — | Custom app; OCI container or custom derivation |
| SparkyFitness | **None** | — | Niche app; OCI container required |
| **pulse** | | | |
| Grafana | `services.grafana` | Well-maintained | Declarative provisioning (datasources, dashboards) |
| Prometheus | `services.prometheus` | Well-maintained | Includes exportarr exporters for ARR apps |
| Loki | `services.loki` | Well-maintained | Full config as Nix attrset |
| Gatus | `services.gatus` | Basic | ICMP checks need `CAP_NET_RAW` workaround |

### Approach: flake-parts + Colmena + sops-nix

**Why flake-parts:**
- Module system for flake outputs — cleaner than hand-rolling `outputs`
- `perSystem` for devShells/packages, `flake` for nixosConfigurations/colmena
- Composable — each concern (hosts, modules, devShell) as a separate module file
- Well-maintained, widely adopted in the Nix community
- Familiar mental model if you already know NixOS modules

**Flake structure:**
```
nixos-homelab/
  flake.nix                # flake-parts entry point
  flake.lock
  parts/
    hosts.nix              # nixosConfigurations + colmena node definitions
    devshell.nix           # Dev shell with colmena, sops, etc.
  hosts/
    psychosocial/
      default.nix          # Host services config
      hardware-configuration.nix
    byob/default.nix
    sugar/default.nix
    pulse/default.nix
  modules/
    common/
      default.nix          # Users, TZ, SSH, nix settings
      nfs.nix              # NAS mounts
      monitoring.nix       # Alloy / node exporter on every host
    services/              # Reusable service wrappers (optional)
  configs/                 # Static config files (Alloy HCL, Grafana dashboards)
    alloy/
    grafana/
    prometheus/
  secrets/
    psychosocial.yaml      # Per-host SOPS secrets
    byob.yaml
    sugar.yaml
    pulse.yaml
    shared.yaml            # Cross-host secrets
  .sops.yaml               # Key mappings (migrate existing)
```

**Why Colmena over alternatives:**
- Parallel deployment across 4 hosts (configurable concurrency)
- Built-in `deployment.keys` for out-of-band secret upload
- Stateless — aligns with GitOps model
- `deployment.buildOnTarget` option for offloading builds
- Most recommended fleet tool in NixOS community (~1.4k stars)

**Why not deploy-rs:** Magic rollback is nice but less actively maintained, no parallel deploy, more verbose config.

**Why not plain nixos-rebuild:** No parallelism, no fleet management, doesn't scale even for 4 hosts.

**Secrets with sops-nix:**
- Uses existing age keys at `/etc/homelab/sops/keys.txt` (`sops.age.keyFile`)
- Decrypts at NixOS activation time to `/run/secrets/<name>` (never in Nix store)
- Per-secret file ownership/permissions
- `sops.templates` generates `.env`-style files for OCI containers
- Can optionally derive keys from SSH host keys via `ssh-to-age` (eliminates separate key management)

### Network Model Change

**Same-host:** Container name resolution (`lab-authelia:9091`) becomes `127.0.0.1:9091`. Services bind to localhost by default.

**Cross-host:** Already uses IP:port in Caddy config (`10.10.50.10:8989`). During staging, Caddy points at staging IPs. After cutover, IPs swap back.

**Firewall:** NixOS `networking.firewall` replaces Docker's opaque iptables rules. Per-service port opening, per-interface control. Many modules have `openFirewall` options.

**Security improvement:** Docker's flat bridge network allows all containers to talk freely. NixOS services bound to `127.0.0.1` require explicit firewall openings for cross-host access.

### Service Isolation Comparison

| Docker | NixOS systemd | Notes |
|--------|---------------|-------|
| Overlay filesystem | `ProtectSystem = "strict"` | Makes / read-only except specified paths |
| PID namespace | `ProtectProc = "invisible"` | Not full isolation but hides other procs |
| `no-new-privileges` | `NoNewPrivileges = true` | Direct equivalent |
| `cap_drop: ALL` | `CapabilityBoundingSet = ""` | Direct equivalent |
| `mem_limit` | `MemoryMax = "512M"` | Direct equivalent via cgroups |
| Network namespace | Firewall + bind address | Docker wins here — full network isolation per container |

**Verdict:** Adequate for homelab behind OPNsense on private VLANs. Use `systemd-analyze security <service>` to audit.

### Log Collection Change

Current: Alloy reads Docker logs via `/var/run/docker.sock` with `discovery.docker`.

NixOS: Services log to journald. Alloy uses `loki.source.journal` component.

**Impact:** Grafana dashboards need query updates: `container="lab-sonarr"` → `unit="sonarr.service"`.

### TLS — No Functional Change

Caddy with `withPlugins` for Cloudflare DNS works identically as native service. Cert storage moves to `/var/lib/caddy`. The NixOS module handles this automatically.

### Alternative Approaches Considered

1. **Full Docker on NixOS (compose2nix only)** — Rejected. Misses the main benefit of NixOS: declarative service management. Good as transitional step though.
2. **NixOS containers (`nixos-container`)** — Rejected. Adds complexity without Docker's ecosystem benefits. Systemd sandboxing is sufficient.
3. **Podman instead of Docker** — Considered. NixOS `oci-containers` supports both backends. Podman is rootless by default but has ARR app compatibility concerns. Docker is safer for LinuxServer.io images.
4. **Raw flake outputs instead of flake-parts** — Rejected. Works for small flakes but gets messy with colmena + nixosConfigurations + devShells. flake-parts keeps it modular.

### Risks & Rollback

- **Risk:** VPN routing for byob (Media VLAN, VPN-only internet). Docker sidecar approach doesn't translate. Need WireGuard namespace or network namespace.
  - **Mitigation:** Keep byob on Docker via `oci-containers` initially. Solve VPN routing as a separate task.
- **Risk:** Nextcloud migration complexity (PHP config, occ commands, data paths).
  - **Mitigation:** The NixOS module actually handles this better than Docker. Follow the [NixOS Wiki guide](https://wiki.nixos.org/wiki/Nextcloud).
- **Risk:** Service downtime during migration.
  - **Mitigation:** Staging IPs — both old and new VMs run simultaneously. Zero downtime cutover.
- **Risk:** Homepage `HOMEPAGE_VAR_*` env substitution pattern doesn't translate directly.
  - **Mitigation:** Use `services.homepage-dashboard.services` with secrets injected via `environmentFile`.
- **Rollback:** Old Ubuntu VMs stay on Proxmox (just stopped) for 2 weeks after cutover. Additionally, NixOS has `nixos-rebuild switch --rollback` for config-level rollback.

### References

- [NixOS & Flakes Book — Modularize Config](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration)
- [Managing Multi-Host Homelab with NixOS (arsfeld)](https://blog.arsfeld.dev/posts/2025/06/10/managing-homelab-with-nixos/)
- [flake-parts documentation](https://flake.parts/)
- [Colmena Documentation](https://colmena.cli.rs/unstable/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Secret Management on NixOS with sops-nix (Stapelberg 2025)](https://michael.stapelberg.ch/posts/2025-08-24-secret-management-with-sops-nix/)
- [compose2nix](https://github.com/aksiksi/compose2nix)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [NixOS Caddy Wiki](https://wiki.nixos.org/wiki/Caddy)
- [NixOS Nextcloud Wiki](https://wiki.nixos.org/wiki/Nextcloud)
- [NixOS Systemd Hardening](https://nixos.wiki/wiki/Systemd_Hardening)
- [Caddy withPlugins PR](https://github.com/NixOS/nixpkgs/pull/358586)
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)

---

## Implementation Plan

### Migration Order

1. **Phase 0:** ~~Set up the flake repo~~ **DONE** — `HomeLab` branch in nixflake
2. **Phase 1:** `pulse` (monitoring) — lowest risk, best NixOS module coverage
3. **Phase 2:** `sugar` (self-hosted apps) — mix of native + OCI containers
4. **Phase 3:** `byob` (media/ARR) — mostly OCI containers, VPN routing challenge
5. **Phase 4:** `psychosocial` (proxy/auth) — highest risk, migrate last
6. **sulfur** stays Ubuntu+Docker

### Per-Host Migration Process

**Phase A: NixOS + Docker (1:1 parity)**
1. Create new Proxmox VM with staging IP, boot NixOS ISO
2. Use `nixos-anywhere` + `disko` for automated install
3. Enable Docker, use `oci-containers` to replicate existing containers
4. `rsync` data from old VM (`/var/lib/homelab/*`)
5. Copy SOPS keys to `/etc/homelab/sops/keys.txt`
6. Verify all services work at staging IP
7. Update Caddy on psychosocial to point at staging IP — verify end-to-end

**Phase B: Convert to native services (per-service, no rush)**
1. Replace Docker containers with NixOS modules one at a time
2. Keep OCI containers for services without good modules
3. Update Alloy config for journald collection
4. Update Grafana dashboards for new label names

**Phase C: IP cutover**
1. Stop old Ubuntu VM
2. Change NixOS VM IP from staging to production
3. Restart, verify
4. Keep old VM disk for 2 weeks as rollback

---

### File: `flake.nix` (CREATE)

```nix
{
  description = "DockerLab NixOS Homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    flake-parts.url = "github:hercules-ci/flake-parts";

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ./parts/hosts.nix
        ./parts/devshell.nix
      ];
    };
}
```

### File: `parts/hosts.nix` (CREATE)

```nix
{ inputs, ... }:

let
  # Common modules imported by every host
  commonModules = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    ../modules/common
  ];

  # Host metadata — IPs used by colmena for deployment
  # During staging, use staging IPs. After cutover, update to production IPs.
  hostMeta = {
    psychosocial = { ip = "10.10.30.110"; };  # staging (prod: 10.10.30.10)
    byob         = { ip = "10.10.50.110"; };  # staging (prod: 10.10.50.10)
    sugar        = { ip = "10.10.30.111"; };  # staging (prod: 10.10.30.11)
    pulse        = { ip = "10.10.30.112"; };  # staging (prod: 10.10.30.12)
  };

  mkHost = hostname: inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = commonModules ++ [
      ../hosts/${hostname}
      { networking.hostName = hostname; }
    ];
  };
in
{
  flake = {
    nixosConfigurations = builtins.mapAttrs (name: _: mkHost name) hostMeta;

    colmena = {
      meta = {
        nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
        specialArgs = { inherit inputs; };
      };

      defaults = { ... }: {
        imports = commonModules;
      };
    } // builtins.mapAttrs (name: meta: { ... }: {
      imports = [ ../hosts/${name} ];
      networking.hostName = name;
      deployment = {
        targetHost = meta.ip;
        targetUser = "root";
      };
    }) hostMeta;
  };
}
```

### File: `parts/devshell.nix` (CREATE)

```nix
{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Deployment
        colmena
        # Secrets
        sops
        age
        ssh-to-age
        # Nix tools
        nixos-anywhere
        nil  # Nix LSP
        nixfmt-rfc-style
      ];
    };
  };
}
```

### File: `modules/common/default.nix` (CREATE)

```nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./nfs.nix
    ./monitoring.nix
  ];

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Timezone
  time.timeZone = "Europe/Oslo";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.users.odin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Firewall — enabled by default, hosts open ports as needed
  networking.firewall.enable = true;

  # Host resolution for inter-server communication
  # During staging, both old and new IPs are reachable
  networking.hosts = {
    "10.10.30.10"  = [ "psychosocial-old" ];
    "10.10.30.110" = [ "psychosocial" ];
    "10.10.50.10"  = [ "byob-old" ];
    "10.10.50.110" = [ "byob" ];
    "10.10.30.11"  = [ "sugar-old" ];
    "10.10.30.111" = [ "sugar" ];
    "10.10.30.12"  = [ "pulse-old" ];
    "10.10.30.112" = [ "pulse" ];
    "10.10.30.14"  = [ "sulfur" ];
    "10.10.10.20"  = [ "truenas" ];
  };

  # SOPS — use existing age keys
  sops = {
    age.keyFile = "/etc/homelab/sops/keys.txt";
    age.generateKey = false;
  };

  # Docker (for OCI containers on hosts that need it)
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  virtualisation.oci-containers.backend = "docker";

  # Common packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    jq
  ];

  # Boot — limit generations to prevent /boot filling up
  boot.loader.systemd-boot.configurationLimit = 10;

  system.stateVersion = "25.05";
}
```

### File: `modules/common/nfs.nix` (CREATE)

```nix
{ config, lib, ... }:

{
  # NAS NFS mounts — matches current /etc/fstab entries
  # Default: noauto. Hosts opt in by removing noauto from options.

  fileSystems."/mnt/nas/media" = {
    device = "10.10.10.20:/mnt/big/media";
    fsType = "nfs";
    options = [
      "defaults"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noauto"
    ];
  };

  fileSystems."/mnt/nas/downloads" = {
    device = "10.10.10.20:/mnt/medium/downloads";
    fsType = "nfs";
    options = [
      "defaults"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noauto"
    ];
  };

  fileSystems."/mnt/nas/backups" = {
    device = "10.10.10.20:/mnt/medium/backups";
    fsType = "nfs";
    options = [
      "defaults"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "_netdev"
      "noauto"
    ];
  };
}
```

### File: `modules/common/monitoring.nix` (CREATE)

```nix
{ config, pkgs, ... }:

{
  # Grafana Alloy for log + metric collection on every host
  services.alloy.enable = true;

  # Grant journal read access for log collection
  systemd.services.alloy.serviceConfig = {
    SupplementaryGroups = [ "systemd-journal" ];
  };

  # Prometheus node exporter for system metrics
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    port = 9100;
  };
  networking.firewall.allowedTCPPorts = [ 9100 ];
}
```

### File: `hosts/pulse/default.nix` (CREATE)

First host to migrate — fully native monitoring stack.

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # SOPS secrets for this host
  sops.defaultSopsFile = ../../secrets/pulse.yaml;

  sops.secrets.grafana_admin_password = { owner = "grafana"; };
  sops.secrets.grafana_oauth_client_id = { owner = "grafana"; };
  sops.secrets.grafana_oauth_client_secret = { owner = "grafana"; };
  sops.secrets.gatus_oidc_client_secret = {};

  # Firewall — expose service ports to homelab VLAN
  networking.firewall.allowedTCPPorts = [
    3000  # Grafana
    3100  # Loki
    8080  # Gatus
    9090  # Prometheus
  ];

  # --- Prometheus ---
  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "30d";
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            "10.10.30.110:9100"  # psychosocial (staging)
            "10.10.50.110:9100"  # byob (staging)
            "10.10.30.111:9100"  # sugar (staging)
            "127.0.0.1:9100"     # pulse (local)
          ];
        }];
      }
      {
        job_name = "caddy";
        static_configs = [{
          targets = [ "10.10.30.110:2019" ];
        }];
      }
      {
        job_name = "authelia";
        static_configs = [{
          targets = [ "10.10.30.110:9959" ];
        }];
      }
    ];
  };

  # --- Loki ---
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      auth_enabled = false;

      common = {
        path_prefix = "/var/lib/loki";
        ring.kvstore.store = "inmemory";
        replication_factor = 1;
      };

      schema_config.configs = [{
        from = "2024-01-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];

      storage_config.filesystem.directory = "/var/lib/loki/chunks";

      query_range.results_cache.cache.embedded_cache = {
        enabled = true;
        max_size_mb = 100;
      };

      limits_config = {
        retention_period = "30d";
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        delete_request_store = "filesystem";
        retention_enabled = true;
      };
    };
  };

  # --- Grafana ---
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        root_url = "https://grafana.pytt.io";
      };
      analytics.reporting_enabled = false;

      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        client_id = "$__file{${config.sops.secrets.grafana_oauth_client_id.path}}";
        client_secret = "$__file{${config.sops.secrets.grafana_oauth_client_secret.path}}";
        scopes = "openid profile email groups";
        auth_url = "https://auth.pytt.io/api/oidc/authorization";
        token_url = "https://auth.pytt.io/api/oidc/token";
        api_url = "https://auth.pytt.io/api/oidc/userinfo";
        login_attribute_path = "preferred_username";
        name_attribute_path = "name";
        email_attribute_path = "email";
        use_refresh_token = true;
        allow_sign_up = true;
        role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";
      };
    };

    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://127.0.0.1:3100";
        }
      ];
      dashboards.settings.providers = [{
        name = "default";
        options.path = "/etc/grafana/dashboards";
        options.foldersFromFilesStructure = true;
      }];
    };
  };

  # Grafana admin password from SOPS
  sops.templates."grafana-env".content = ''
    GF_SECURITY_ADMIN_PASSWORD=${config.sops.placeholder.grafana_admin_password}
  '';
  systemd.services.grafana.serviceConfig.EnvironmentFile =
    config.sops.templates."grafana-env".path;

  # --- Gatus ---
  services.gatus = {
    enable = true;
    environmentFile = config.sops.templates."gatus-env".path;
  };

  sops.templates."gatus-env".content = ''
    GATUS_OIDC_CLIENT_SECRET=${config.sops.placeholder.gatus_oidc_client_secret}
    DOMAIN=pytt.io
  '';
}
```

### File: `hosts/byob/default.nix` (CREATE)

ARR stack as OCI containers (Phase A — Docker parity).

```nix
{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  sops.defaultSopsFile = ../../secrets/byob.yaml;

  # Enable NAS mounts — remove noauto to activate
  fileSystems."/mnt/nas/media".options = lib.mkForce [
    "defaults" "x-systemd.automount" "x-systemd.idle-timeout=600" "_netdev"
  ];
  fileSystems."/mnt/nas/downloads".options = lib.mkForce [
    "defaults" "x-systemd.automount" "x-systemd.idle-timeout=600" "_netdev"
  ];

  networking.firewall.allowedTCPPorts = [
    8989 7878 9696 8686 6789 9091 5055
  ];

  # Create Docker network
  systemd.services.create-docker-networks = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    script = ''
      ${pkgs.docker}/bin/docker network inspect iowa >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create iowa
    '';
  };

  # ARR stack as OCI containers
  virtualisation.oci-containers.containers = {
    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [
        "/var/lib/homelab/sonarr:/config"
        "/mnt/nas/media/tv:/tv"
        "/mnt/nas/downloads:/downloads"
      ];
      ports = [ "8989:8989" ];
      extraOptions = [ "--network=iowa" ];
    };

    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [
        "/var/lib/homelab/radarr:/config"
        "/mnt/nas/media/movies:/movies"
        "/mnt/nas/downloads:/downloads"
      ];
      ports = [ "7878:7878" ];
      extraOptions = [ "--network=iowa" ];
    };

    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [ "/var/lib/homelab/prowlarr:/config" ];
      ports = [ "9696:9696" ];
      extraOptions = [ "--network=iowa" ];
    };

    lidarr = {
      image = "lscr.io/linuxserver/lidarr:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [
        "/var/lib/homelab/lidarr:/config"
        "/mnt/nas/media/audio:/music"
        "/mnt/nas/downloads:/downloads"
      ];
      ports = [ "8686:8686" ];
      extraOptions = [ "--network=iowa" ];
    };

    nzbget = {
      image = "lscr.io/linuxserver/nzbget:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [
        "/var/lib/homelab/nzbget:/config"
        "/mnt/nas/downloads:/downloads"
      ];
      ports = [ "6789:6789" ];
      extraOptions = [ "--network=iowa" ];
    };

    transmission = {
      image = "lscr.io/linuxserver/transmission:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [
        "/var/lib/homelab/transmission:/config"
        "/mnt/nas/downloads:/downloads"
      ];
      ports = [ "9091:9091" ];
      extraOptions = [ "--network=iowa" ];
    };

    overseerr = {
      image = "lscr.io/linuxserver/overseerr:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [ "/var/lib/homelab/overseerr:/config" ];
      ports = [ "5055:5055" ];
      extraOptions = [ "--network=iowa" ];
    };
  };
}
```

### File: `hosts/psychosocial/default.nix` (CREATE)

Fully native Caddy + Authelia + Homepage (migrated last).

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  sops.defaultSopsFile = ../../secrets/psychosocial.yaml;

  sops.secrets = {
    cloudflare_api_token = {};
    authelia_jwt_secret = { owner = "authelia-main"; };
    authelia_session_secret = { owner = "authelia-main"; };
    authelia_storage_encryption_key = { owner = "authelia-main"; };
    authelia_redis_password = { owner = "authelia-main"; };
    authelia_oidc_hmac_secret = { owner = "authelia-main"; };
  };

  networking.firewall.allowedTCPPorts = [
    443   # Caddy HTTPS
    9959  # Authelia metrics
  ];

  # --- Caddy ---
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare" ];
      hash = ""; # Fill after first build attempt — nix will tell you the hash
    };

    globalConfig = ''
      servers {
        metrics
      }
    '';

    virtualHosts."*.pytt.io" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }

        @auth host auth.pytt.io
        handle @auth {
          reverse_proxy 127.0.0.1:9091
        }

        @home host home.pytt.io
        handle @home {
          forward_auth 127.0.0.1:9091 {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Email
          }
          reverse_proxy 127.0.0.1:3000
        }

        # Cross-host: use production IPs after cutover
        @sonarr host sonarr.pytt.io
        handle @sonarr {
          reverse_proxy 10.10.50.10:8989
        }

        @radarr host radarr.pytt.io
        handle @radarr {
          reverse_proxy 10.10.50.10:7878
        }

        @grafana host grafana.pytt.io
        handle @grafana {
          reverse_proxy 10.10.30.12:3000
        }

        # ... remaining reverse proxy entries

        handle {
          respond "Not found" 404
        }
      '';
    };
  };

  sops.templates."caddy-env".content = ''
    CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflare_api_token}
  '';
  systemd.services.caddy.serviceConfig.EnvironmentFile =
    config.sops.templates."caddy-env".path;

  # --- Authelia ---
  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
      sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
      oidcHmacSecretFile = config.sops.secrets.authelia_oidc_hmac_secret.path;
      oidcIssuerPrivateKeyFile = "/etc/homelab/authelia/oidc.pem";
    };

    settings = {
      theme = "dark";
      server.address = "tcp://0.0.0.0:9091";

      telemetry.metrics = {
        enabled = true;
        address = "tcp://0.0.0.0:9959";
      };

      session = {
        cookies = [{
          domain = "pytt.io";
          authelia_url = "https://auth.pytt.io";
          default_redirection_url = "https://home.pytt.io";
        }];
        redis = {
          host = "10.10.10.20";
          port = 30059;
        };
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      authentication_backend.file.path =
        "/var/lib/authelia-main/users_database.yml";

      access_control = {
        default_policy = "deny";
        rules = [
          { domain = "auth.pytt.io"; policy = "bypass"; }
          {
            domain = [ "*.pytt.io" ];
            policy = "one_factor";
          }
        ];
      };

      notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";

      identity_providers.oidc = {
        # OIDC client definitions — pre-hashed secrets are safe here
      };
    };
  };

  # Redis password for Authelia session
  sops.templates."authelia-env".content = ''
    AUTHELIA_SESSION_REDIS_PASSWORD=${config.sops.placeholder.authelia_redis_password}
  '';
  systemd.services.authelia-main.serviceConfig.EnvironmentFile =
    config.sops.templates."authelia-env".path;

  # --- Homepage ---
  services.homepage-dashboard = {
    enable = true;
    listenPort = 3000;
    # Declarative service config + secrets via environmentFile
  };

  # --- Webhook (for sulfur deploy — the one remaining Ubuntu host) ---
  services.webhook = {
    enable = true;
    port = 9000;
  };
}
```

### File: `hosts/sugar/default.nix` (CREATE)

Mix of native services and OCI containers.

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  sops.defaultSopsFile = ../../secrets/sugar.yaml;

  sops.secrets = {
    norish_db_pass = {};
    norish_master_key = {};
    norish_oidc_client_secret = {};
    n8n_db_password = {};
    searxng_secret = {};
    nextcloud_db_pass = {};
    nextcloud_admin_pass = {};
    nextcloud_redis_pass = {};
  };

  networking.firewall.allowedTCPPorts = [
    3000 3001 3003 3004 3456 5678 6767 8080 8086 8888
    69  # netboot TFTP
  ];
  networking.firewall.allowedUDPPorts = [ 69 ];  # TFTP

  # Create Docker network for OCI containers
  systemd.services.create-docker-networks = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    script = ''
      ${pkgs.docker}/bin/docker network inspect iowa >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create iowa
    '';
  };

  # --- Native services ---

  # SearXNG
  services.searx = {
    enable = true;
    package = pkgs.searxng;
    redisCreateLocally = true;
    environmentFile = config.sops.templates."searxng-env".path;
    settings = {
      server = {
        port = 8888;
        bind_address = "0.0.0.0";
        secret_key = "@SEARXNG_SECRET@";  # Replaced from environmentFile
      };
      # Import rest from existing settings.yml
    };
  };

  sops.templates."searxng-env".content = ''
    SEARXNG_SECRET=${config.sops.placeholder.searxng_secret}
  '';

  # Nextcloud (excellent NixOS module)
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.pytt.io";
    package = pkgs.nextcloud30;
    config = {
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
      dbtype = "pgsql";
      dbhost = "10.10.10.20";
      dbport = 5432;
      dbname = "nextcloud";
      dbpassFile = config.sops.secrets.nextcloud_db_pass.path;
    };
    settings.overwriteprotocol = "https";
    caching.redis = true;
    maxUploadSize = "1G";
    phpOptions = {
      memory_limit = "512M";
    };
  };

  services.redis.servers.nextcloud = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
    requirePassFile = config.sops.secrets.nextcloud_redis_pass.path;
  };

  # n8n
  services.n8n = {
    enable = true;
  };
  systemd.services.n8n.serviceConfig.EnvironmentFile =
    config.sops.templates."n8n-env".path;

  sops.templates."n8n-env".content = ''
    DB_TYPE=postgresdb
    DB_POSTGRESDB_HOST=10.10.10.20
    DB_POSTGRESDB_PORT=5432
    DB_POSTGRESDB_DATABASE=n8n
    DB_POSTGRESDB_USER=n8n
    DB_POSTGRESDB_PASSWORD=${config.sops.placeholder.n8n_db_password}
    N8N_SECURE_COOKIE=false
    N8N_METRICS=true
  '';

  # --- OCI containers (no NixOS module) ---

  virtualisation.oci-containers.containers = {
    perplexica = {
      image = "itzcrazykns1337/perplexica:slim-latest";
      environment = {
        SEARXNG_API_URL = "http://127.0.0.1:8888";
      };
      volumes = [
        "lab-perplexica-data:/home/perplexica/data"
        "lab-perplexica-uploads:/home/perplexica/uploads"
      ];
      ports = [ "3001:3000" ];
      extraOptions = [ "--network=iowa" ];
    };

    netbootxyz = {
      image = "ghcr.io/netbootxyz/netbootxyz:latest";
      environment = {
        PUID = "1000"; PGID = "1000"; TZ = "Europe/Oslo";
      };
      volumes = [ "/var/lib/homelab/netbootxyz/config:/config" ];
      ports = [ "3003:3000" "69:69/udp" "8086:80" ];
      extraOptions = [ "--network=iowa" ];
    };

    norish = {
      image = "norishapp/norish:latest";
      environmentFiles = [ config.sops.templates."norish-env".path ];
      volumes = [ "lab-norish-data:/app/uploads" ];
      ports = [ "3000:3000" ];
      extraOptions = [ "--network=iowa" ];
    };

    myrlin = {
      image = "lab-myrlin:latest";
      volumes = [ "lab-myrlin-state:/app/state" ];
      ports = [ "3456:3456" ];
      extraOptions = [ "--network=iowa" ];
    };

    paseo = {
      image = "lab-paseo:latest";
      volumes = [ "lab-paseo-data:/data" ];
      ports = [ "6767:6767" ];
      extraOptions = [ "--network=iowa" ];
    };

    sparkyfitness-frontend = {
      image = "codewithcj/sparkyfitness:latest";
      environment = {
        TZ = "Europe/Oslo";
        SPARKY_FITNESS_FRONTEND_URL = "https://sparkyfitness.pytt.io";
        SPARKY_FITNESS_SERVER_HOST = "lab-sparkyfitness-backend";
        SPARKY_FITNESS_SERVER_PORT = "3010";
      };
      ports = [ "3004:80" ];
      extraOptions = [ "--network=iowa" ];
    };

    sparkyfitness-backend = {
      image = "codewithcj/sparkyfitness_server:latest";
      environmentFiles = [ config.sops.templates."sparkyfitness-env".path ];
      extraOptions = [ "--network=iowa" ];
    };
  };

  sops.templates."norish-env".content = ''
    AUTH_URL=https://norish.pytt.io
    DATABASE_URL=postgres://norish:${config.sops.placeholder.norish_db_pass}@10.10.10.20:5432/norish
    MASTER_KEY=${config.sops.placeholder.norish_master_key}
    OIDC_NAME=Authelia
    OIDC_ISSUER=https://auth.pytt.io
    OIDC_CLIENT_ID=norish
    OIDC_CLIENT_SECRET=${config.sops.placeholder.norish_oidc_client_secret}
    TRUSTED_ORIGINS=https://norish.pytt.io
  '';
}
```

### File: `.sops.yaml` (CREATE — new repo)

```yaml
creation_rules:
  - path_regex: secrets/byob\.yaml$
    age: age1_arr_low_key
  - path_regex: secrets/psychosocial\.yaml$
    age: age1_critical_key
  - path_regex: secrets/(sugar|pulse|shared)\.yaml$
    age: age1_general_key
```

### Manual Steps

1. **Create new Proxmox VMs** with staging IPs (see table above)
   - Boot from NixOS minimal ISO or use nixos-anywhere
   - Same VM specs as current Ubuntu VMs

2. **Generate hardware-configuration.nix** on each new VM:
   ```bash
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

3. **Copy age keys** to each new VM:
   ```bash
   scp /etc/homelab/sops/keys.txt root@10.10.30.112:/etc/homelab/sops/keys.txt
   ```

4. **Copy Authelia OIDC private key** (psychosocial only):
   ```bash
   scp /etc/homelab/authelia/oidc.pem root@10.10.30.110:/etc/homelab/authelia/oidc.pem
   ```

5. **Convert SOPS secrets** from `.env` format to YAML per host:
   ```bash
   sops secrets/pulse.yaml
   # Add: grafana_admin_password, grafana_oauth_client_id, etc.
   ```

6. **Migrate data** from old VMs:
   ```bash
   rsync -avz --progress root@10.10.30.12:/var/lib/homelab/ root@10.10.30.112:/var/lib/homelab/
   ```

7. **Build custom images** for myrlin/paseo on sugar (they use `docker build`):
   ```bash
   # On sugar-nix, build the images that are currently built from Dockerfiles
   docker build -t lab-myrlin:latest /path/to/myrlin/
   docker build -t lab-paseo:latest /path/to/paseo/
   ```

8. **Update Caddy on old psychosocial** to point at staging IPs during verification:
   ```
   # Temporarily proxy to staging pulse for testing
   @grafana host grafana.pytt.io
   handle @grafana {
     reverse_proxy 10.10.30.112:3000  # staging pulse
   }
   ```

9. **Update Grafana dashboards** — change label filters:
   - `container="lab-sonarr"` → `unit="sonarr.service"` (native services)
   - Docker-based services keep container labels

10. **IP cutover** (per host, after verification):
    - Stop old Ubuntu VM
    - Change NixOS VM IP: staging → production
    - `nixos-rebuild switch` to apply new IP
    - Verify

### Verification

For each migrated host:

1. `systemctl status <service>` for all native services; `docker ps` for OCI containers
2. Check Grafana Loki for logs from the new host
3. Check Prometheus targets page — new host's exporters green
4. Verify all subdomains resolve and return correct content via Caddy
5. Test OIDC login (Grafana, Norish) and forward auth (Homepage, Prometheus)
6. `ls -la /run/secrets/` — secrets decrypted with correct permissions
7. `df -h /mnt/nas/*` on byob — NFS mounts working
8. `nixos-rebuild switch --rollback` — verify previous generation boots
