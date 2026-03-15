---
name: desktop-plan-module
description: Research a module for NixOS desktop machines and create an implementation plan
allowed-tools: Read, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, mcp__nixos__nix, mcp__nixos__nix_versions
model: opus
argument-hint: <module-name> [on <host>]
---

# Research & Plan a new desktop module

Research everything needed to add a module to a NixOS desktop machine, then produce a plan in `plans/<module>.md`. **Does NOT modify project files.**

## Step 1: Parse arguments

Parse `$ARGUMENTS` for module name and optional host. Default to `profiles/base.nix` (all desktops) if no host. Valid hosts: `laptop`, `vnpc-21`, `station`.

## Step 2: Determine module layer

| Layer | Directory | When to use |
|-------|-----------|-------------|
| **NixOS** | `modules/nixos/` | Hardware, system services, daemons, security |
| **Home-manager** | `modules/home-manager/<category>/` | CLI tools, desktop apps, user services, dotfiles |

HM categories: `app/` (desktop apps), `cli/` (terminal tools), `misc/` (browsers, standalone), `desktop/` (WM configs)

## Step 3: Research

### 3a. NixOS/HM module availability (MCP)

- `action: "search", source: "nixos", type: "options", query: "services.<module>"` or `programs.<module>`
- `action: "search", source: "nixos", type: "packages", query: "<module>"`
- `mcp__nixos__nix_versions`: `package: "<module>"`

Determine: native NixOS module? HM module? Or manual package + config?

### 3b. Service docs (web, if needed)

Only if module options are insufficient. Record: key config options, default ports, dependencies.

## Step 4: Read codebase state

Read the target `default.nix` for imports, an existing similar module as reference, and the target host/profile.

## Step 5: Write the plan file

Write to `plans/<module>.md`. Use the module patterns documented in `modules/nixos/CLAUDE.md`.

```markdown
# <Module Name>

**Status:** plan-complete
**Layer:** nixos / home-manager
**Category:** <category (HM only)>
**Enable in:** <profile or host>
**Date:** <today>

## Research

### NixOS/HM Module
- **Available:** yes / no
- **Module path:** `programs.<name>` / `services.<name>`
- **Key options:** <list>

### Dependencies
- <other modules, packages, config needed>

### Notes
- <quirks, gotchas>

---

## Implementation Plan

### File: `modules/<layer>/<file>.nix` (CREATE)
\`\`\`nix
<exact module content>
\`\`\`

### File: `modules/<layer>/<category>/default.nix` (EDIT)
Add: `./<file>.nix`

### File: `profiles/base.nix` or `hosts/<host>/default.nix` (EDIT)
Add: `<module>.enable = true;`

### Verification
- `nix flake check` passes
- `just rebuild` succeeds
```

Plan should be **copy-paste ready**. Tell user to review and run `/desktop-add-module <module>` to execute.
