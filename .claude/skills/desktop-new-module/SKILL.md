---
name: desktop-new-module
description: Full pipeline — research, plan, and add a module to a NixOS desktop machine with review between phases
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Bash, Agent, mcp__nixos__nix, mcp__nixos__nix_versions
argument-hint: <module-name> [on <host>]
---

# New Desktop Module Pipeline

End-to-end pipeline for adding a module to a NixOS desktop machine. Runs two phases with user review between them.

Parse `$ARGUMENTS` for the module name and optional target host (e.g. `/desktop-new-module localsend on laptop`). If the module name is missing, ask the user.

Valid desktop hosts: `laptop`, `vnpc-21`, `station` (or omit for all desktops via `profiles/base.nix`)

---

## Phase 1: Research & Plan

Use the **Agent tool** with `subagent_type: "general-purpose"` and `model: "sonnet"` to run the research and planning phase.

Give the subagent this prompt (filling in the module name and host):

> Read the skill file at `.claude/skills/desktop-plan-module/SKILL.md` and follow its instructions exactly.
> Module: `<module-name>`, Host: `<host>` (or "all desktops" if no host specified).
> Write the output to `plans/<module-name>.md`.

Wait for the subagent to finish, then read `plans/<module-name>.md` and display the research findings and implementation plan to the user.

### Review gate

Ask the user:

**"Research & plan complete. Review the plan above. Ready to execute?"**

Options:
- **Execute the plan** — proceed to Phase 2
- **Edit plan first** — pause so the user can edit `plans/<module-name>.md` manually, then re-read and continue
- **Stop here** — end the pipeline (plan is saved for later `/desktop-add-module`)

---

## Phase 2: Execute

Use the **Agent tool** with `subagent_type: "general-purpose"` and `model: "sonnet"` to run the execution phase.

Give the subagent this prompt (filling in the module name):

> Read the skill file at `.claude/skills/desktop-add-module/SKILL.md` and follow its instructions exactly.
> Module: `<module-name>`.
> The plan file is at `plans/<module-name>.md`.
> Execute all changes described in the Implementation Plan section.
> After execution, move the plan to `plans/archive/<module-name>.md`.

Wait for the subagent to finish, then display the summary of all changes made.

---

## If the user stops at the gate

The plan file at `plans/<module-name>.md` is preserved. Tell the user they can:
- Edit the file and resume with `/desktop-add-module <module>`
- Or re-run `/desktop-new-module <module>` later
