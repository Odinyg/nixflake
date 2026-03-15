---
name: desktop-add-module
description: Execute the implementation plan to add a module to a NixOS desktop machine
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__nixos__nix
model: sonnet
argument-hint: <module-name>
---

# Add a desktop module (execute plan)

Execute the implementation plan from `plans/<module>.md` to add a module to a NixOS desktop machine.

**Prerequisites:** The plan file must exist and have `Status: plan-complete`. If not, tell the user to run `/desktop-plan-module` first.

## Parse arguments

Parse `$ARGUMENTS` for the module name (e.g. `/desktop-add-module localsend`). If missing, check `plans/` for plan-complete files and ask.

## Step 1: Read and validate the plan

Read `plans/<module>.md`. Verify:
- `**Status:** plan-complete` is present
- The Implementation Plan section exists with concrete Nix expressions

If the plan is missing or incomplete, stop and tell the user.

## Step 2: Execute each change

Follow the plan's Implementation Plan section **exactly**. For each file listed:

### CREATE files
- Write new module files with exact content from the plan
- Verify the parent directory exists

### EDIT files
- Read the target file first
- For `modules/<layer>/default.nix` or `modules/<layer>/<category>/default.nix`: add the import in the imports list
- For `profiles/base.nix`: add the enable line in the appropriate section (match existing style/grouping)
- For `hosts/<host>/default.nix`: add the enable line in the host-specific overrides section

## Step 3: Verify

### 3a. Read back files
- Read each created/modified file to confirm edits look correct
- Check Nix syntax (balanced braces, semicolons, proper indentation)

### 3b. Run flake check
```bash
nix flake check
```
If it fails, read the error, fix the issue, and re-run until it passes.

## Step 4: Archive the plan

Move the plan file to the archive:
```bash
mkdir -p plans/archive
mv plans/<module>.md plans/archive/<module>.md
```

## Step 5: Summary

Show the user:

**Files created:**
- List new files

**Files modified:**
- List modified files and what changed

**Next steps:**
- Rebuild: `just rebuild`

**Plan archived to:** `plans/archive/<module>.md`
