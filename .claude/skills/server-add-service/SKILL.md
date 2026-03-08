---
name: server-add-service
description: Execute the implementation plan to add a service to a NixOS homelab server
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__nixos__nix
model: sonnet
argument-hint: <service-name>
---

# Add a server service (execute plan)

Execute the implementation plan from `plans/<service>.md` to add a service to a NixOS homelab server.

**Prerequisites:** The plan file must exist and have `Status: plan-complete`. If not, tell the user to run `/server-plan-service` first.

## Parse arguments

Parse `$ARGUMENTS` for the service name (e.g. `/server-add-service grafana`). If missing, check `plans/` for plan-complete files and ask.

## Step 1: Read and validate the plan

Read `plans/<service>.md`. Verify:
- `**Status:** plan-complete` is present
- The Implementation Plan section exists with concrete Nix expressions

If the plan is missing or incomplete, stop and tell the user.

## Step 2: Execute each change

Follow the plan's Implementation Plan section **exactly**. For each file listed:

### EDIT files
- Read the target file first
- Apply the edit as specified in the plan
- For `hosts/<host>/default.nix`: add the service config block in a logical position (imports at top, sops.secrets early, services in order, firewall ports grouped)
- For `hosts/psychosocial/default.nix`: add Caddy route block in the virtualHosts section, alphabetically
- For `modules/server/*.nix`: if creating a reusable module, also register it in `modules/server/default.nix` imports

### CREATE files
- Write new module files with exact content from the plan
- Verify the parent directory exists

### REMINDER files (like secrets/*.yaml)
- Do NOT edit encrypted files — just note them in the summary

## Step 3: Verify

After all changes:

### 3a. Read back files
- Read each created/modified file to confirm edits look correct
- Check Nix syntax (balanced braces, semicolons, proper indentation)

### 3b. Run flake check
```bash
nix flake check
```
If it fails, read the error, fix the issue, and re-run until it passes.

## Step 4: Archive the plan

Move the plan file to the archive:
```bash
mkdir -p plans/archive
mv plans/<service>.md plans/archive/<service>.md
```

## Step 5: Summary

Show the user:

**Files created:**
- List new files

**Files modified:**
- List modified files and what changed

**Manual steps remaining:**
- Add secrets: `sops secrets/<host>.yaml` — add the listed secret keys
- Database creation (if needed): `/server-create-db <service>`
- OIDC client registration in Authelia (if auth mode is oidc)
- Deploy: `colmena apply --on <host>`
- Verify: `systemctl status <service>` on the host

**Plan archived to:** `plans/archive/<service>.md`
