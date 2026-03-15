---
name: server-audit-service
description: Full pipeline — research, plan, and fix an existing NixOS server service with review between each phase
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Bash, Agent, mcp__nixos__nix, mcp__nixos__nix_versions
argument-hint: <service-name> or <host-name>
---

# Audit Server Service Pipeline

End-to-end audit pipeline. Parse `$ARGUMENTS` for service name or host name. If a **host** is given (`psychosocial`, `byob`, `sugar`, `pulse`), read its config to identify all services and audit each sequentially. Ask if missing.

## Phase 1: Research & Plan

Use **Agent** (`subagent_type: "general-purpose"`, `model: "opus"`):

> Read `.claude/skills/server-plan-audit/SKILL.md` and follow it exactly.
> Service: `<service-name>`. Write to `plans/audit-<service-name>.md`.

Display results. If `Status: audit-clean`, skip to next service or end.

Ask: **"Audit plan complete for <service>. <X> critical, <Y> important, <Z> minor. Ready to apply fixes?"**
- **Apply all** → Phase 2
- **Edit first** → pause for manual edits, then continue
- **Stop** → plan saved for `/server-apply-audit`
- **Skip minor** → only apply critical and important

## Phase 2: Apply

Use **Agent** (`subagent_type: "general-purpose"`, `model: "sonnet"`):

> Read `.claude/skills/server-apply-audit/SKILL.md` and follow it exactly.
> Service: `<service-name>`. Plan at `plans/audit-<service-name>.md`.

Display summary. For multi-service mode, ask **"Continue to next service: <next>?"** between each.
