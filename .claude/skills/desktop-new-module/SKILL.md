---
name: desktop-new-module
description: Full pipeline — research, plan, and add a module to a NixOS desktop machine with review between phases
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Bash, Agent, mcp__nixos__nix, mcp__nixos__nix_versions
argument-hint: <module-name> [on <host>]
---

# New Desktop Module Pipeline

End-to-end pipeline: research, plan, review, execute. Parse `$ARGUMENTS` for module name and optional host. Valid hosts: `laptop`, `vnpc-21`, `station` (omit for all desktops via `profiles/base.nix`). Ask if module name missing.

## Phase 1: Research & Plan

Use **Agent** (`subagent_type: "general-purpose"`, `model: "opus"`):

> Read `.claude/skills/desktop-plan-module/SKILL.md` and follow it exactly.
> Module: `<module-name>`, Host: `<host>` (or "all desktops"). Write output to `plans/<module-name>.md`.

Display the plan, then ask: **"Research & plan complete. Ready to execute?"**
- **Execute** → Phase 2
- **Edit first** → pause for manual edits to `plans/<module-name>.md`, then continue
- **Stop** → plan saved for later `/desktop-add-module`

## Phase 2: Execute

Use **Agent** (`subagent_type: "general-purpose"`, `model: "sonnet"`):

> Read `.claude/skills/desktop-add-module/SKILL.md` and follow it exactly.
> Module: `<module-name>`. Plan at `plans/<module-name>.md`.
> Execute all changes, then move plan to `plans/archive/<module-name>.md`.

Display the summary of changes made.
