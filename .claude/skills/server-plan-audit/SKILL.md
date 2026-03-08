---
name: server-plan-audit
description: Research best practices and produce a fix plan for an existing NixOS server service
allowed-tools: Read, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, mcp__nixos__nix, mcp__nixos__nix_versions
model: sonnet
argument-hint: <service-name>
---

# Research & plan audit for an existing server service

Research best practices for a service running on a NixOS homelab server, compare against current config, and produce an exact implementation plan. **This skill does NOT modify project files** — it only writes to the plan file.

## Parse arguments

Parse `$ARGUMENTS` for the service name (e.g. `/server-plan-audit grafana`). If missing, scan `hosts/*/default.nix` for configured services and ask.

---

## Part 1: Research

### Step 1: Read current config

Find the service config by grepping `hosts/*/default.nix` for the service name. Read the host's config to understand:
- Whether it's a native NixOS service or OCI container
- Current settings and options used
- Current secrets setup (sops.secrets / sops.templates)
- Current firewall rules
- Current Caddy route (if on psychosocial)

Also read:
- `modules/server/default.nix` — common server modules applied
- `.sops.yaml` — secret tiers

### Step 2: Research NixOS module options (MCP)

Use `mcp__nixos__nix` to discover ALL available options:

```
action: "search", source: "nixos", type: "options", query: "services.<service-name>"
action: "info", source: "nixos", type: "options", query: "services.<service-name>"
```

Compare available options against what's currently configured. Identify:
- Useful options not currently used
- Deprecated options being used
- Better patterns available in newer NixOS versions

Check version:
```
mcp__nixos__nix_versions: package: "<service-name>"
```

### Step 3: Research auth capabilities

Search for OIDC/OAuth2 support:
- If current auth is `none` but OIDC is supported → flag as improvement
- If using forward auth but OIDC is available → flag as upgrade opportunity

### Step 4: Research systemd hardening

Check what hardening options are available for this service:

```
action: "search", source: "nixos", type: "options", query: "systemd.services.<service-name>"
```

Also search the web for `NixOS <service> systemd hardening` and `systemd-analyze security <service>`.

Key hardening options to check:
- `ProtectSystem = "strict"` / `ProtectHome = true`
- `NoNewPrivileges = true`
- `PrivateTmp = true`
- `CapabilityBoundingSet` restrictions
- `MemoryDenyWriteExecute = true`
- `ReadWritePaths` / `ReadOnlyPaths`

### Step 5: Research database strategy

If the service uses a database:
- Is it using the optimal backend? (NAS postgres vs local sqlite vs sidecar)
- Are connection parameters correct?
- Should backup be configured?

### Step 6: Research logging and monitoring

- Is the service logging to journald properly?
- Does it expose Prometheus metrics? If so, is a scrape target configured?
- Could Alloy collect additional data?

### Step 7: Check wiki and community practices

```
action: "search", source: "wiki", query: "<service-name>"
WebSearch: "NixOS <service-name> best practices 2025"
```

---

## Part 2: Plan

### Step 8: Convention compliance check

Compare the service config against NixOS and repo conventions:

#### Service configuration
- [ ] Uses native NixOS module (if available) instead of OCI container
- [ ] All meaningful module options are set (not relying on poor defaults)
- [ ] Settings use the `settings` attrset pattern where available

#### Secrets management
- [ ] Secrets use `sops.secrets` with proper ownership
- [ ] No plaintext secrets in the Nix store
- [ ] `sops.templates` used for env file injection (OCI containers)
- [ ] Secret file permissions are restrictive

#### Firewall
- [ ] Only necessary ports open
- [ ] Uses `openFirewall` option if module supports it
- [ ] No overly permissive rules

#### Systemd hardening
- [ ] `NoNewPrivileges = true`
- [ ] `ProtectSystem` and `ProtectHome` set
- [ ] `PrivateTmp = true`
- [ ] Appropriate capability restrictions
- [ ] Resource limits (MemoryMax, etc.) if appropriate

#### Networking
- [ ] Service binds to correct address (localhost for local-only, 0.0.0.0 for cross-host)
- [ ] Caddy route correct (if proxied)

#### Data persistence
- [ ] State directory configured properly
- [ ] Backup strategy for data

### Step 9: Combine findings and prioritize

Categorize each finding:
- **Critical** — security issue, plaintext secret, missing hardening
- **Important** — unused OIDC, suboptimal module usage, missing options
- **Minor** — cosmetic, optional hardening, missing metrics

---

## Output

Write everything to `plans/audit-<service>.md`:

```markdown
# Audit: <Service Name>

**Status:** plan-complete
**Host:** <host>
**Date:** <today>

## Current State
- **Type:** native / oci-container
- **Module:** `services.<name>` / `virtualisation.oci-containers.containers.<name>`
- **Auth mode:** none / oidc / authelia
- **Database:** <current strategy>

## Research Findings

### Module Options
- **Current coverage:** <what's configured vs available>
- **Missing useful options:** <list>

### Auth
- **Current:** <mode>
- **OIDC available:** yes / no
- **Action:** none / upgrade to OIDC

### Systemd Hardening
- **Current score:** <from systemd-analyze if available>
- **Improvements:** <list of hardening options to add>

### Database
- **Current:** <strategy>
- **Recommended:** <same or different>

### Logging & Monitoring
- **Prometheus metrics:** available / configured / not available
- **Action:** <add scrape target / none>

---

## Audit Results

### Summary
- **Critical:** <count>
- **Important:** <count>
- **Minor:** <count>
- **Pass:** <count>

### Findings

#### [Critical/Important/Minor] <Finding title>
**Current:** <what it is now>
**Expected:** <what it should be>
**Details:** <explanation>

---

## Implementation Plan

### File: `hosts/<host>/default.nix` (EDIT)
\`\`\`nix
# OLD:
<old content>

# NEW:
<new content>
\`\`\`

### File: `modules/server/<file>.nix` (EDIT/CREATE)
<if changes to shared modules>

### File: `secrets/<host>.yaml` (REMINDER)
<if new secrets needed>

### Verification
- `nix flake check` passes
- `colmena apply --on <host>` deploys successfully
- `systemctl status <service>` shows active
- `systemd-analyze security <service>.service` score improved
```

Each change should be **exact and copy-paste ready**.

If everything passes, set status to `audit-clean` and skip the Implementation Plan section.

Tell the user the plan is ready for review and they can run `/server-apply-audit <service>` to execute.
