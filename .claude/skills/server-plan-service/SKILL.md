---
name: server-plan-service
description: Research a service for NixOS homelab servers and create a concrete implementation plan
allowed-tools: Read, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, mcp__nixos__nix, mcp__nixos__nix_versions
model: sonnet
argument-hint: <service-name> on <host>
---

# Research & Plan a new homelab server service

Research everything needed to add a service to a NixOS homelab server, then produce an exact implementation plan. Write everything to `plans/<service>.md`. **This skill does NOT create or modify any project files** — it only gathers information and writes the plan file.

## Step 1: Parse arguments

Parse `$ARGUMENTS` for the service name and target host (e.g. `/server-plan-service grafana on pulse`). If either is missing, ask the user.

Valid hosts: `psychosocial`, `byob`, `sugar`, `pulse`

## Step 2: Research

### 2a. Check NixOS module availability (MCP)

Use `mcp__nixos__nix` to discover if a native NixOS module exists:

```
action: "search", source: "nixos", type: "options", query: "services.<service-name>"
action: "info", source: "nixos", type: "options", query: "services.<service-name>"
action: "search", source: "nixos", type: "packages", query: "<service-name>"
```

Also check version availability:
```
mcp__nixos__nix_versions: package: "<service-name>"
```

Classify the service:
- **Native module** — `services.<name>` exists with good option coverage → use NixOS module directly
- **OCI container** — no module or too basic → use `virtualisation.oci-containers.containers.<name>`
- **Custom derivation** — custom app with source code → build with `pkgs.stdenv.mkDerivation` or similar

### 2b. Research the service (web)

Search for official documentation, Docker Compose examples, and NixOS wiki entries:

1. **Official docs** — self-hosting / installation page
2. **NixOS wiki** — `wiki.nixos.org/wiki/<Service>`
3. **Docker image** (if OCI container) — LinuxServer.io first, GHCR second, Docker Hub fallback
4. **GitHub repo** — official compose file for correct ports, volumes, env vars

Record:
- Default web UI port
- Required environment variables
- Required volumes/data paths
- Database needs (postgres, redis, sqlite, none)
- Config file format and location

### 2c. Auth capabilities

Search for `<service> OIDC` or `<service> OAuth2`:

- OIDC/OAuth2 supported → `oidc` (connect to Authelia)
- Built-in login only → `none` (Caddy proxies directly)
- No auth at all → `authelia` (forward auth via Caddy)

### 2d. Homepage widget

Check if a [homepage-dashboard widget](https://gethomepage.dev/widgets/services/) exists:
- Fetch `https://gethomepage.dev/widgets/services/<service>/`
- Record widget type and required fields

## Step 3: Read codebase state

Read these files to understand current state:

- `hosts/<host>/default.nix` — current host config
- `modules/server/default.nix` — common server modules
- `parts/lib.nix` — how server hosts are built
- `.sops.yaml` — current secret key tiers
- An existing host config as reference (e.g. `hosts/pulse/default.nix`)

## Step 4: Build the implementation plan

Using research + codebase context, determine the exact changes.

### Host IPs (for Caddy routes on psychosocial)

| Host | Staging IP | Production IP |
|------|------------|---------------|
| psychosocial | 10.10.30.110 | 10.10.30.10 |
| byob | 10.10.50.110 | 10.10.50.10 |
| sugar | 10.10.30.111 | 10.10.30.11 |
| pulse | 10.10.30.112 | 10.10.30.12 |

### Secrets pattern (sops-nix)

```nix
# In host default.nix
sops.secrets.<secret_name> = { owner = "<service-user>"; };

# For env file injection into OCI containers
sops.templates."<service>-env".content = ''
  VAR_NAME=${config.sops.placeholder.<secret_name>}
'';
```

### Native service pattern

```nix
services.<name> = {
  enable = true;
  settings = { ... };
};
networking.firewall.allowedTCPPorts = [ <port> ];
```

### OCI container pattern

```nix
virtualisation.oci-containers.containers.<name> = {
  image = "<image>";
  environment = { ... };
  volumes = [ ... ];
  ports = [ "<host>:<container>" ];
  environmentFiles = [ config.sops.templates."<name>-env".path ];
};
```

### Caddy route (if service is NOT on psychosocial)

The Caddy config on psychosocial needs a route added. For native NixOS Caddy:
```nix
# In hosts/psychosocial/default.nix
@<service> host <service>.pytt.io
handle @<service> {
    reverse_proxy <host-ip>:<port>
}
```

## Step 5: Write the plan file

Write everything to `plans/<service>.md`:

```markdown
# <Service Name>

**Status:** plan-complete
**Host:** <host>
**Date:** <today>
**Type:** native / oci-container / custom

## Research

### NixOS Module
- **Available:** yes / no
- **Module path:** `services.<name>`
- **Option coverage:** full / partial / none
- **Details:** <key options, gaps>

### Image (OCI only)
- **Reference:** <full-image>
- **Source:** LinuxServer / GHCR / Docker Hub
- **Web UI Port:** <port>
- **Docs:** <url>

### Environment Variables
- `VAR_NAME` — purpose (required/optional)

### Volumes / Data Paths
- `/path` — purpose

### Database
- **Type:** none / sqlite / postgres-nas / redis-nas / sidecar
- **Details:** <version requirements>

### Auth
- **Mode:** none / oidc / authelia
- **Details:** <OIDC docs link, etc.>

### Homepage Widget
- **Available:** yes / no
- **Type:** <widget-type>
- **Fields:** <key, url, etc.>

### Notes
- Any quirks, gotchas, or special setup steps

---

## Implementation Plan

### File: `hosts/<host>/default.nix` (EDIT)
Add:
\`\`\`nix
<exact Nix content>
\`\`\`

### File: `secrets/<host>.yaml` (REMINDER)
Add these secrets (encrypted):
- `<secret_name>: <description>`

### File: `hosts/psychosocial/default.nix` (EDIT) — if Caddy route needed
Add route:
\`\`\`nix
<exact Caddy route block>
\`\`\`

### File: `modules/server/<module>.nix` (CREATE) — if reusable module
\`\`\`nix
<exact module content>
\`\`\`

### Manual Steps
- <database creation, OIDC registration, data migration, etc.>

### Verification
- `nix flake check` passes
- `colmena apply --on <host>` deploys successfully
- `systemctl status <service>` shows active
- Web UI accessible at `https://<service>.pytt.io`

---

## Pre-deploy Checklist

- [ ] **Host config** — service added to `hosts/<host>/default.nix`
- [ ] **Firewall** — port opened in `networking.firewall.allowedTCPPorts`
- [ ] **Secrets** — added to `secrets/<host>.yaml` via SOPS
- [ ] **Caddy route** — added to psychosocial config (if not local)
- [ ] **Database** — creation steps documented (if needed)
- [ ] **Auth** — OIDC client registered or forward auth configured
- [ ] **flake check** — `nix flake check` passes
```

The plan should be **copy-paste ready** — exact Nix expressions, no ambiguity.

Tell the user the plan is ready for review and they can run `/server-add-service <service>` to execute it.
