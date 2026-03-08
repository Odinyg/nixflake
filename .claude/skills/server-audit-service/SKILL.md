---
name: server-audit-service
description: Full pipeline — research, plan, and fix an existing NixOS server service with review between each phase
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Bash, Agent, mcp__nixos__nix, mcp__nixos__nix_versions
argument-hint: <service-name> or <host-name>
---

# Audit Server Service Pipeline

End-to-end pipeline to audit an existing NixOS server service (or all services on a host). Runs two phases with user review between each.

Parse `$ARGUMENTS` for the service name or host name (e.g. `/server-audit-service grafana` or `/server-audit-service pulse`).

If a **host name** is given (`psychosocial`, `byob`, `sugar`, `pulse`), read its `hosts/<host>/default.nix` to identify all configured services and run the pipeline for each one sequentially.

If missing, ask the user.

---

## Phase 1: Research & Plan

Use the **Agent tool** with `subagent_type: "general-purpose"` and `model: "sonnet"` to run the research and planning phase.

Give the subagent this prompt (filling in the service name):

> Read the skill file at `.claude/skills/server-plan-audit/SKILL.md` and follow its instructions exactly.
> Service: `<service-name>`.
> Write findings and plan to `plans/audit-<service-name>.md`.

Wait for the subagent to finish, then read `plans/audit-<service-name>.md` and display the audit results and implementation plan.

If the plan says `Status: audit-clean`, tell the user the service passes all checks and skip to the next service (or end).

### Review gate

Ask the user:

**"Audit plan complete for <service>. <X> critical, <Y> important, <Z> minor findings. Ready to apply fixes?"**

Options:
- **Apply all fixes** — proceed to Phase 2
- **Edit plan first** — pause for manual edits, then continue
- **Stop here** — plan is saved for later `/server-apply-audit`
- **Skip minor fixes** — only apply critical and important

---

## Phase 2: Apply

Use the **Agent tool** with `subagent_type: "general-purpose"` and `model: "sonnet"` to run the execution phase.

Give the subagent this prompt (filling in the service name):

> Read the skill file at `.claude/skills/server-apply-audit/SKILL.md` and follow its instructions exactly.
> Service: `<service-name>`.
> The plan file is at `plans/audit-<service-name>.md`.

Wait for the subagent to finish, then display the summary of all changes made.

---

## Multi-service mode

When auditing an entire host, after completing (or skipping) one service, ask:

**"<service> audit complete. Continue to next service: <next-service>?"**

Options:
- **Continue** — start Phase 1 for the next service
- **Stop here** — end the pipeline

---

## If the user stops at any gate

The plan file at `plans/audit-<service>.md` is preserved. Tell the user they can:
- Resume with `/server-apply-audit <service>`
- Or re-run `/server-audit-service <service>` later
