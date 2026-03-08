---
name: server-new-service
description: Full pipeline — research, plan, and add a service to a NixOS homelab server with review between each phase
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Bash, Agent, mcp__nixos__nix, mcp__nixos__nix_versions
argument-hint: <service-name> on <host>
---

# New Server Service Pipeline

End-to-end pipeline for adding a service to a NixOS homelab server. Runs two phases with user review between them.

Parse `$ARGUMENTS` for the service name and target host (e.g. `/server-new-service grafana on pulse`). If either is missing, ask the user.

Valid hosts: `psychosocial`, `byob`, `sugar`, `pulse`

---

## Phase 1: Research & Plan

Use the **Agent tool** with `subagent_type: "general-purpose"` and `model: "sonnet"` to run the research and planning phase.

Give the subagent this prompt (filling in the service name and host):

> Read the skill file at `.claude/skills/server-plan-service/SKILL.md` and follow its instructions exactly.
> Service: `<service-name>`, Host: `<host>`.
> Write the output to `plans/<service-name>.md`.

Wait for the subagent to finish, then read `plans/<service-name>.md` and display the research findings and implementation plan to the user.

### Review gate

Ask the user:

**"Research & plan complete. Review the findings and implementation plan above. Ready to execute?"**

Options:
- **Execute the plan** — proceed to Phase 2
- **Edit plan first** — pause so the user can edit `plans/<service-name>.md` manually, then re-read and continue
- **Stop here** — end the pipeline (plan is saved for later `/server-add-service`)

---

## Phase 2: Execute

Use the **Agent tool** with `subagent_type: "general-purpose"` and `model: "sonnet"` to run the execution phase.

Give the subagent this prompt (filling in the service name):

> Read the skill file at `.claude/skills/server-add-service/SKILL.md` and follow its instructions exactly.
> Service: `<service-name>`.
> The plan file is at `plans/<service-name>.md`.
> Execute all changes described in the Implementation Plan section.
> After execution, move the plan to `plans/archive/<service-name>.md`.

Wait for the subagent to finish, then display the summary of all changes made.

---

## If the user stops at the gate

The plan file at `plans/<service-name>.md` is preserved. Tell the user they can:
- Edit the file and resume with `/server-add-service <service>`
- Or re-run `/server-new-service <service> on <host>` later
