---
name: desktop-plan-module
description: Research a module for NixOS desktop machines and create an implementation plan
allowed-tools: Read, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, mcp__nixos__nix, mcp__nixos__nix_versions
model: sonnet
argument-hint: <module-name> [on <host>]
---

# Research & Plan a new desktop module

Research everything needed to add a module to a NixOS desktop machine, then produce an implementation plan. Write everything to `plans/<module>.md`. **This skill does NOT create or modify any project files** — it only gathers information and writes the plan file.

## Step 1: Parse arguments

Parse `$ARGUMENTS` for the module name and optional target host (e.g. `/desktop-plan-module localsend on laptop`).

If no host specified, default to enabling in `profiles/base.nix` (all desktops).

Valid desktop hosts: `laptop`, `vnpc-21`, `station`

## Step 2: Determine module layer

Ask the user if unclear:

| Layer | Directory | When to use |
|-------|-----------|-------------|
| **NixOS (system)** | `modules/nixos/` | Hardware, system services, daemons, security, firewall |
| **Home-manager (user)** | `modules/home-manager/<category>/` | CLI tools, desktop apps, user services, dotfiles |

Home-manager categories:
- `app/` — desktop applications (discord, media, communication, utilities)
- `cli/` — terminal tools (git, tmux, neovim, zsh, languages)
- `misc/` — browsers, standalone tools (firefox, chromium, thunar, gammastep)
- `desktop/` — window manager configs (hyprland, bspwm)

## Step 3: Research

### 3a. Check NixOS module/package availability (MCP)

```
action: "search", source: "nixos", type: "options", query: "services.<module>" or "programs.<module>"
action: "search", source: "nixos", type: "packages", query: "<module>"
mcp__nixos__nix_versions: package: "<module>"
```

Determine:
- Is there a native NixOS module (`services.*` or `programs.*`)?
- Is there a home-manager module (`programs.*` or `services.*` in HM)?
- Or does it need manual package + config?

### 3b. Research the module (web, if needed)

Only if the NixOS/HM module options are insufficient:
- Official docs / GitHub repo
- NixOS wiki entry
- Configuration format and required settings

Record:
- Key configuration options
- Default ports (if a service)
- Any dependencies (other modules, packages)

## Step 4: Read codebase state

Read these files to understand current state:

- The target `default.nix` for imports (e.g. `modules/nixos/default.nix` or `modules/home-manager/<category>/default.nix`)
- An existing similar module as reference for the pattern
- The target host config or profile where it will be enabled

## Step 5: Write the plan file

Write to `plans/<module>.md`:

```markdown
# <Module Name>

**Status:** plan-complete
**Layer:** nixos / home-manager
**Category:** <category (for HM modules)>
**Enable in:** <profile or host>
**Date:** <today>

## Research

### NixOS/HM Module
- **Available:** yes / no
- **Module path:** `programs.<name>` / `services.<name>`
- **Key options:** <list important options>

### Dependencies
- <other modules, packages, or config needed>

### Notes
- <quirks, gotchas, special setup>

---

## Implementation Plan

### File: `modules/<layer>/<file>.nix` (CREATE)
\`\`\`nix
<exact module content>
\`\`\`

### File: `modules/<layer>/<category>/default.nix` (EDIT) — import the new module
Add:
\`\`\`nix
./<file>.nix
\`\`\`

### File: `profiles/base.nix` or `hosts/<host>/default.nix` (EDIT) — enable the module
Add:
\`\`\`nix
<module>.enable = true;
\`\`\`

### Verification
- `nix flake check` passes
- `just rebuild` succeeds
```

### Module templates

**NixOS system module:**
```nix
{ lib, config, ... }:
let
  cfg = config.<name>;
in
{
  options.<name> = {
    enable = lib.mkEnableOption "<description>";
  };

  config = lib.mkIf cfg.enable {
    # service/program config here
  };
}
```

**Home-manager user module:**
```nix
{ config, lib, ... }:
{
  options = {
    <name> = {
      enable = lib.mkEnableOption "<description>";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.<name>.enable {
    # user-level config here
  };
}
```

The plan should be **copy-paste ready** — exact Nix expressions, no ambiguity.

Tell the user the plan is ready for review and they can run `/desktop-add-module <module>` to execute it.
