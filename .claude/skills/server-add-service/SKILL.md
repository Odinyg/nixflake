---
name: server-add-service
description: Execute the implementation plan to add a service to a NixOS homelab server
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__nixos__nix
model: sonnet
argument-hint: <service-name>
---

# Add a server service (execute plan)

Execute the plan from `plans/<service>.md`. Requires `Status: plan-complete`. If missing, tell user to run `/server-plan-service` first.

## Step 1: Read and validate

Read `plans/<service>.md`. Verify status and that Implementation Plan has concrete Nix expressions.

## Step 2: Execute each change

Follow the Implementation Plan **exactly**:

- **EDIT files** — Read target first, apply edits. Host configs: imports at top, sops early, services in order, firewall grouped. Caddy routes: alphabetical.
- **CREATE files** — Write with exact content. If creating `modules/server/*.nix`, also add import to `modules/server/default.nix`.
- **Database** — If PostgreSQL needed, add to `server.postgresql.databases` in host config.

## Step 3: Verify

Read back all modified files. Check Nix syntax. Run `nix flake check` (git add new files first). Fix and re-run until passing.

## Step 4: Archive and summarize

```bash
mkdir -p plans/archive && mv plans/<service>.md plans/archive/<service>.md
```

Show: files created, files modified, manual steps remaining (secrets via `/server-add-secrets`, deploy via `colmena apply --on <host>`, verify via `systemctl status`).
