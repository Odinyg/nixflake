# ntfy (Self-Hosted Push Notifications)

**Status:** plan-complete
**Host:** pulse
**Date:** 2026-03-17
**Type:** native

## Research

### NixOS Module
- **Available:** yes
- **Module path:** `services.ntfy-sh`
- **Option coverage:** full — `enable`, `settings` (YAML submodule), `user`, `group`, `package`
- **Package:** `ntfy-sh` 2.18.0 on unstable

### Image (OCI only)
- N/A — using native NixOS module

### Environment Variables
- None required for basic setup — ntfy uses a YAML/server.yml config file, mapped via `services.ntfy-sh.settings`

### Volumes / Data Paths
- `/var/lib/ntfy-sh/` — default state directory (cache DB, attachments)

### Database
- **Type:** sqlite (default, built-in — stores messages, users, access tokens)

### Auth
- **Mode:** authelia — ntfy has no native OIDC support (open feature request). Use Authelia forward auth via Caddy for web UI access. The ntfy publish/subscribe API uses its own token-based auth for programmatic access (scripts, phone apps).

### Homepage Widget
- **Available:** no (no native widget — can use `customapi` with `/v1/stats` endpoint)

### Notes
- ntfy default port is 80; we override to 2586 to avoid conflicts
- The `listen-http` setting takes the form `:PORT`
- ntfy has a built-in web UI at the root URL for subscribing/publishing
- Phone apps (Android/iOS) connect directly to the ntfy instance URL
- For programmatic access (scripts, Gatus, Grafana alerts), clients use bearer tokens — Authelia forward auth should only protect the web UI, not the API paths
- The `/v1/health` endpoint can be used for uptime checks
- Attachments can be enabled with `attachment-cache-dir` if needed later

---

## Implementation Plan

### File: `modules/server/ntfy.nix` (CREATE)
```nix
{
  config,
  lib,
  ...
}:
let
  cfg = config.server.ntfy;
in
{
  options.server.ntfy = {
    enable = lib.mkEnableOption "ntfy push notification service";
    port = lib.mkOption {
      type = lib.types.port;
      default = 2586;
      description = "Port for the ntfy web interface and API";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for ntfy";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        listen-http = ":${toString cfg.port}";
        base-url = "https://ntfy.${cfg.domain}";
        behind-proxy = true;
        auth-default-access = "deny-all";
      };
    };

    systemd.services.ntfy-sh = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
```

### File: `modules/server/default.nix` (EDIT)
Add to the imports list, in the `# Monitoring (pulse)` section:
```nix
    # Monitoring (pulse)
    ./prometheus.nix
    ./loki.nix
    ./grafana.nix
    ./gatus.nix
    ./ntfy.nix
```

### File: `hosts/pulse/default.nix` (EDIT)
Add under the existing services block:
```nix
  server.ntfy.enable = true;
```

### File: `hosts/psychosocial/default.nix` (EDIT)
Add Caddy route in the `# --- pulse ---` section. ntfy needs special handling: the web UI gets Authelia forward auth, but API paths must bypass it for programmatic access (phone apps, scripts):
```nix
      @ntfy host ntfy.pytt.io
      handle @ntfy {
        # API and publish/subscribe paths bypass Authelia for programmatic access
        @ntfy_api path /v1/* /*.json /*/json /*/sse /*/raw /*/ws /*/auth /*/publish
        handle @ntfy_api {
          reverse_proxy 10.10.30.12:2586
        }
        # Web UI uses Authelia SSO
        handle {
          import authelia
          reverse_proxy 10.10.30.12:2586
        }
      }
```

### File: `secrets/pulse.yaml` (REMINDER)
- No secrets needed for initial setup
- If enabling access control later, add: `ntfy_admin_password: <admin password for ntfy user management>`

### Manual Steps
1. After deployment, create an admin user for ntfy access control (optional, for later):
   ```bash
   ssh odin@pulse
   sudo ntfy user add --role=admin admin
   ```
2. Configure phone apps to point to `https://ntfy.pytt.io`
3. For Grafana alerting integration, create an ntfy topic and configure Grafana contact points to POST to `https://ntfy.pytt.io/<topic>`

### Verification
- `nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath` — evaluates without error
- `colmena apply --on pulse` deploys
- `curl http://10.10.30.12:2586/v1/health` returns `{"healthy":true}`
- Web UI accessible at `https://ntfy.pytt.io`
- Test notification: `curl -d "Test message" https://ntfy.pytt.io/test`

---

## Pre-deploy Checklist
- [ ] Module created (`modules/server/ntfy.nix`)
- [ ] Module imported in `modules/server/default.nix`
- [ ] Host config updated (`hosts/pulse/default.nix`)
- [ ] Firewall port opened (2586)
- [ ] Caddy route added on psychosocial (with API path bypass for Authelia)
- [ ] No secrets needed for initial setup
- [ ] No database steps needed (uses built-in SQLite)
- [ ] Auth: Authelia forward auth on web UI, deny-all default for API
- [ ] `nix eval` passes
