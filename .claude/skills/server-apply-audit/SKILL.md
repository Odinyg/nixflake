---
name: server-apply-audit
description: Execute audit fixes from the plan to improve an existing NixOS server service
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
argument-hint: <service-name>
---

# Apply server audit fixes

Execute the changes from `plans/audit-<service>.md` to fix an existing NixOS server service.

**Prerequisites:** The plan file must have `Status: plan-complete`. If `Status: audit-clean`, tell the user everything already passes — nothing to fix.

## Parse arguments

Parse `$ARGUMENTS` for the service name (e.g. `/server-apply-audit grafana`). If missing, check `plans/audit-*.md` for plan-complete files.

## Step 1: Read and validate the plan

Read `plans/audit-<service>.md`. Verify:
- `**Status:** plan-complete` is present
- The Implementation Plan section has concrete changes

If status is `audit-clean`, inform the user and stop.

## Step 2: Execute each change

Follow the plan's Implementation Plan section **exactly**. For each file:

### EDIT files
- Read the target file first
- Apply each old → new replacement as specified
- Verify the old text exists before attempting the edit

### CREATE files
- Write new files (e.g. new server modules)
- Verify parent directories exist
- If creating a module in `modules/server/`, also add the import to `modules/server/default.nix`

### Order of operations
1. Shared modules (`modules/server/*.nix`) — if any changes
2. Host config (`hosts/<host>/default.nix`) — main changes
3. Secrets (`secrets/<host>.yaml`) — note only, don't edit encrypted files

## Step 3: Verify

After all changes:

### 3a. Read back files
- Read each modified file to confirm edits are correct
- Check Nix syntax (balanced braces, semicolons)

### 3b. Run flake check
```bash
nix flake check
```
If it fails, read the error, fix the issue, and re-run until it passes.

## Step 4: Archive the plan

```bash
mkdir -p plans/archive
mv plans/audit-<service>.md plans/archive/audit-<service>.md
```

## Step 5: Summary

Show the user:

**Fixes applied:**
- List each finding that was fixed (with severity)

**Files modified:**
- List each file and what changed

**Manual steps remaining:**
- Encrypted secret changes: `sops secrets/<host>.yaml`
- Deploy: `colmena apply --on <host>`
- Verify: `systemctl status <service>` and `systemd-analyze security <service>.service`

**Skipped (if any):**
- Changes that couldn't be applied automatically and why

**Plan archived to:** `plans/archive/audit-<service>.md`
