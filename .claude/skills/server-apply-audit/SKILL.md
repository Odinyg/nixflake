---
name: server-apply-audit
description: Execute audit fixes from the plan to improve an existing NixOS server service
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
argument-hint: <service-name>
---

# Apply server audit fixes

Execute changes from `plans/audit-<service>.md`. Requires `Status: plan-complete`. If `audit-clean`, inform user and stop.

## Step 1: Read and validate

Read the plan. Verify status and concrete changes in Implementation Plan.

## Step 2: Execute changes

Follow the plan **exactly**. Order: shared modules first, then host config, then note secret changes.

- **EDIT** — Read target first, verify old text exists, apply replacement
- **CREATE** — Write new files, add imports to `modules/server/default.nix` if needed

## Step 3: Verify

Read back modified files. Check Nix syntax. Run `nix flake check`, fix until passing.

## Step 4: Archive and summarize

```bash
mkdir -p plans/archive && mv plans/audit-<service>.md plans/archive/audit-<service>.md
```

Show: fixes applied (with severity), files modified, manual steps (encrypted secrets, deploy, verify with `systemd-analyze security`), skipped items.
