# Server Modules — Homelab services on NixOS

## Adding a New Service
1. Create `modules/server/<service>.nix`
2. Add import to `modules/server/default.nix` (grouped by function — media, monitoring, apps, etc.)
3. Enable in the target host's `hosts/<hostname>/default.nix`
4. Add `homelab.target` membership to the main systemd service

## Module Structure (every service follows this)
```nix
{ config, lib, ... }:
let cfg = config.server.<service>;
in {
  options.server.<service> = {
    enable = lib.mkEnableOption "<service>";
    port = lib.mkOption { type = lib.types.port; default = XXXX; };
    # domain, dbHost, dbPort as needed
  };
  config = lib.mkIf cfg.enable {
    systemd.services.<service> = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
    # ...
  };
}
```

## Rules
- IMPORTANT: Servers use `nixpkgs-unstable` — all NixOS module options and packages are from unstable, no `pkgs-unstable` overlay needed
- IMPORTANT: Every service with a systemd unit MUST join `homelab.target` via `partOf` + `wantedBy`
- Use `lib.types.port` for port options, `lib.types.str` for domains
- Name port options as `<service>Port` (e.g., `sonarrPort`, `metricsPort`)
- Services behind Caddy should NOT open firewall ports directly — Caddy routes traffic
- PostgreSQL passwords: define `sops.secrets.postgresql_<service>_password` — the postgresql module auto-creates DBs/users

## Secrets Patterns
```nix
# Simple secret
sops.secrets.my_secret = { };

# Multi-var env file (preferred for services needing multiple secrets)
sops.templates."service-env".content = ''
  VAR=${config.sops.placeholder.my_secret}
'';
systemd.services.<service>.serviceConfig.EnvironmentFile = config.sops.templates."service-env".path;
```

## Server Assignments (from default.nix imports + host configs)
- **byob**: media (arr, nzbget, transmission, seerr)
- **psychosocial**: reverse proxy + auth (caddy, authelia, homepage) — all `*.pytt.io` routes
- **pulse**: monitoring (prometheus, loki, grafana, gatus, ntfy)
- **sugar**: apps + DB (n8n, searxng, nextcloud, perplexica, netbootxyz, mealie, norish, wger, freshrss, postgresql)
- **spiders**: VPN + auth (netbird, authelia) — public VPS, uses nginx not Caddy
- **all**: base (nfs, monitoring exporters, disko, netbird client)

## Observability Stack
- Logs -> Loki, Metrics -> Prometheus, Dashboards -> Grafana, Health -> Gatus
- Node exporter on port 9100 (all servers), Caddy metrics on 2019
- All services authenticate via Authelia (OIDC) where supported
