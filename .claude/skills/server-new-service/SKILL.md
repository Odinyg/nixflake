---
name: server-new-service
description: Full pipeline — research, plan, and add a service to a NixOS homelab server with review between each phase
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Bash, Agent, mcp__nixos__nix, mcp__nixos__nix_versions
argument-hint: <service-name> on <host>
---

# New Server Service Pipeline

End-to-end pipeline: research, plan, review, execute, secrets. Parse `$ARGUMENTS` for service name and host. Valid hosts: `psychosocial`, `byob`, `sugar`, `pulse`. Ask if missing.

## Phase 1: Research & Plan

Use **Agent** (`subagent_type: "general-purpose"`, `model: "opus"`):

> Read `.claude/skills/server-plan-service/SKILL.md` and follow it exactly.
> Service: `<service-name>`, Host: `<host>`. Write output to `plans/<service-name>.md`.

Display the plan, then ask: **"Research & plan complete. Ready to execute?"**
- **Execute** → Phase 2
- **Edit first** → pause for manual edits to `plans/<service-name>.md`, then continue
- **Stop** → plan saved for later `/server-add-service`

## Phase 2: Execute

Use **Agent** (`subagent_type: "general-purpose"`, `model: "sonnet"`):

> Read `.claude/skills/server-add-service/SKILL.md` and follow it exactly.
> Service: `<service-name>`. Plan at `plans/<service-name>.md`.
> Execute all changes, then move plan to `plans/archive/<service-name>.md`.

Display the summary of changes made.

## Phase 3: Secrets

Automatically run after execution. Use **Agent** (`subagent_type: "general-purpose"`, `model: "opus"`):

> Read `.claude/skills/server-add-secrets/SKILL.md` and follow it exactly.
> Service: `<service-name>`, Host: `<host>`.

Display the secrets summary. The full pipeline is now complete — user just needs to deploy.
