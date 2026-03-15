---
name: server-plan-service
description: Research a service for NixOS homelab servers and create a concrete implementation plan
allowed-tools: Read, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, mcp__nixos__nix, mcp__nixos__nix_versions
model: opus
argument-hint: <service-name> on <host>
---

# Research & Plan a new homelab server service

Research everything needed to add a service, then produce an exact implementation plan in `plans/<service>.md`. **Does NOT modify project files.**

## Step 1: Parse arguments

Parse `$ARGUMENTS` for service name and target host. Valid hosts: `psychosocial`, `byob`, `sugar`, `pulse`. Ask if missing.

## Step 2: Research

### 2a. NixOS module availability (MCP)

**Servers use `nixpkgs-unstable`** — always search the unstable channel for options and packages.

Use `mcp__nixos__nix`:
- `action: "search", source: "nixos", channel: "unstable", type: "options", query: "services.<name>"`
- `action: "info", source: "nixos", channel: "unstable", type: "options", query: "services.<name>"`
- `action: "search", source: "nixos", channel: "unstable", type: "packages", query: "<name>"`
- `mcp__nixos__nix_versions`: `package: "<name>"`

Classify: **Native module** (good options) → use directly | **OCI container** (no/basic module) → `oci-containers` | **Custom** → build from source

### 2b. Service docs (web)

Search for official self-hosting docs, Docker Compose examples, NixOS wiki. Record: default port, env vars, volumes, database needs, config format.

### 2c. Auth capabilities

Search `<service> OIDC` / `OAuth2`. Classify: `oidc` (connect to Authelia) | `none` (built-in login, Caddy proxies) | `authelia` (no auth, forward auth via Caddy)

### 2d. Homepage widget

Check `https://gethomepage.dev/widgets/services/<service>/` for widget type and required fields.

## Step 3: Read codebase state

Read: `hosts/<host>/default.nix`, `modules/server/default.nix`, `parts/lib.nix`, `.sops.yaml`, and one existing host config as reference.

## Step 4: Build the implementation plan

Use research + codebase context. Follow the Nix patterns in `modules/server/CLAUDE.md` for secrets, native services, and OCI containers.

### Host IPs (for Caddy routes on psychosocial)

| Host | Staging IP | Production IP |
|------|------------|---------------|
| psychosocial | 10.10.30.110 | 10.10.30.10 |
| byob | 10.10.50.110 | 10.10.50.10 |
| sugar | 10.10.30.111 | 10.10.30.11 |
| pulse | 10.10.30.112 | 10.10.30.12 |

### Caddy route (if service is NOT on psychosocial)

```nix
# In hosts/psychosocial/default.nix
@<service> host <service>.pytt.io
handle @<service> {
    reverse_proxy <host-ip>:<port>
}
```

## Step 5: Write the plan file

Write to `plans/<service>.md`:

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

### Image (OCI only)
- **Reference:** <image>
- **Web UI Port:** <port>
- **Docs:** <url>

### Environment Variables
- `VAR_NAME` — purpose (required/optional)

### Volumes / Data Paths
- `/path` — purpose

### Database
- **Type:** none / sqlite / postgres / redis

### Auth
- **Mode:** none / oidc / authelia

### Homepage Widget
- **Available:** yes / no
- **Type:** <widget-type>

### Notes
- Quirks, gotchas, special setup steps

---

## Implementation Plan

### File: `hosts/<host>/default.nix` (EDIT)
\`\`\`nix
<exact Nix content>
\`\`\`

### File: `secrets/<host>.yaml` (REMINDER)
- `<secret_name>: <description>`

### File: `hosts/psychosocial/default.nix` (EDIT) — if Caddy route needed
\`\`\`nix
<exact Caddy route block>
\`\`\`

### File: `modules/server/<module>.nix` (CREATE) — if reusable module
\`\`\`nix
<exact module content>
\`\`\`

### Manual Steps
- <database creation, OIDC registration, etc.>

### Verification
- `nix flake check` passes
- `colmena apply --on <host>` deploys
- Web UI accessible at `https://<service>.pytt.io`

---

## Pre-deploy Checklist
- [ ] Host config updated
- [ ] Firewall ports opened
- [ ] Secrets added via SOPS
- [ ] Caddy route added (if not local)
- [ ] Database steps documented
- [ ] Auth configured
- [ ] `nix flake check` passes
```

Plan should be **copy-paste ready**. Tell user to review and run `/server-add-service <service>` to execute.
