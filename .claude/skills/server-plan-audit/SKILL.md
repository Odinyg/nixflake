---
name: server-plan-audit
description: Research best practices and produce a fix plan for an existing NixOS server service
allowed-tools: Read, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, mcp__nixos__nix, mcp__nixos__nix_versions
model: opus
argument-hint: <service-name>
---

# Research & plan audit for an existing server service

Research best practices, compare against current config, produce an exact fix plan in `plans/audit-<service>.md`. **Does NOT modify project files.**

## Parse arguments

Parse `$ARGUMENTS` for service name. If missing, scan `hosts/*/default.nix` for services and ask.

---

## Part 1: Research

### Step 1: Read current config

Grep `hosts/*/default.nix` for the service. Read the host config to understand: native vs OCI, current settings, secrets setup, firewall rules, Caddy route. Also read `modules/server/default.nix` and `.sops.yaml`.

### Step 2: NixOS module options (MCP)

Use `mcp__nixos__nix` to discover all available options. Compare against current config. Identify: useful unused options, deprecated options, better patterns in newer versions.

### Step 3: Auth capabilities

If current auth is `none` but OIDC is available → flag as improvement.

### Step 4: Systemd hardening

Check available hardening: `ProtectSystem`, `ProtectHome`, `NoNewPrivileges`, `PrivateTmp`, `CapabilityBoundingSet`, `MemoryDenyWriteExecute`, `ReadWritePaths`. Search web for `NixOS <service> systemd hardening`.

### Step 5: Database strategy

If using a DB: optimal backend? correct connection params? backup configured?

### Step 6: Logging and monitoring

Proper journald logging? Prometheus metrics available/configured? Alloy collection?

### Step 7: Community practices

Search NixOS wiki and web for `NixOS <service> best practices`.

---

## Part 2: Plan

### Step 8: Convention compliance

Check against these conventions:
- Uses native NixOS module if available
- All meaningful options set (not relying on poor defaults)
- Secrets use `sops.secrets` with proper ownership, no plaintext in Nix store
- Only necessary ports open, uses `openFirewall` if available
- Systemd hardening applied (`NoNewPrivileges`, `ProtectSystem`, `ProtectHome`, `PrivateTmp`)
- Binds to correct address (localhost for local-only, 0.0.0.0 for cross-host)
- State directory configured, backup strategy for data

### Step 9: Prioritize findings

- **Critical** — security issue, plaintext secret, missing hardening
- **Important** — unused OIDC, suboptimal module usage, missing options
- **Minor** — cosmetic, optional hardening, missing metrics

---

## Output

Write to `plans/audit-<service>.md`:

```markdown
# Audit: <Service Name>

**Status:** plan-complete
**Host:** <host>
**Date:** <today>

## Current State
- **Type:** native / oci-container
- **Auth mode:** none / oidc / authelia
- **Database:** <current strategy>

## Research Findings

### Module Options
- **Current coverage:** <configured vs available>
- **Missing useful options:** <list>

### Auth
- **Current:** <mode>
- **OIDC available:** yes / no
- **Action:** none / upgrade to OIDC

### Systemd Hardening
- **Improvements:** <list of options to add>

### Logging & Monitoring
- **Prometheus metrics:** available / configured / not available

---

## Audit Results

### Summary
- **Critical:** <count> | **Important:** <count> | **Minor:** <count> | **Pass:** <count>

### Findings

#### [Critical/Important/Minor] <Finding title>
**Current:** <what it is now>
**Expected:** <what it should be>

---

## Implementation Plan

### File: `hosts/<host>/default.nix` (EDIT)
\`\`\`nix
# OLD:
<old content>
# NEW:
<new content>
\`\`\`

### Verification
- `nix flake check` passes
- `colmena apply --on <host>` deploys
- `systemd-analyze security <service>.service` score improved
```

Each change must be **exact and copy-paste ready**. If everything passes, set `Status: audit-clean` and skip Implementation Plan.

Tell user to review and run `/server-apply-audit <service>` to execute.
