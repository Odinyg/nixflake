---
name: desktop-add-module
description: Execute the implementation plan to add a module to a NixOS desktop machine
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__nixos__nix
model: sonnet
argument-hint: <module-name>
---

# Add a desktop module (execute plan)

Execute the plan from `plans/<module>.md`. Requires `Status: plan-complete`. If missing, tell user to run `/desktop-plan-module` first.

## Step 1: Read and validate

Read `plans/<module>.md`. Verify status and that Implementation Plan has concrete Nix expressions.

## Step 2: Execute each change

Follow the Implementation Plan **exactly**:

- **CREATE** — Write new module files with exact content
- **EDIT** — Read target first. For `default.nix` imports: add to imports list. For profiles/hosts: match existing style/grouping.

## Step 3: Verify

Read back modified files. Check Nix syntax. Run `nix flake check`, fix until passing.

## Step 4: Archive and summarize

```bash
mkdir -p plans/archive && mv plans/<module>.md plans/archive/<module>.md
```

Show: files created, files modified, next step (`just rebuild`).
