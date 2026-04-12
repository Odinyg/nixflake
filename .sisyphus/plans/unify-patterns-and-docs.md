# Unify NixOS Module Patterns & Documentation Overhaul

## TL;DR

> **Quick Summary**: Standardize cfg binding + config guard patterns across all nixos and home-manager modules (server modules are already consistent), then do a full documentation refresh covering all CLAUDE.md files, README.md, and supporting docs.
> 
> **Deliverables**:
> - All nixos modules use `let cfg = config.<name>;` + `lib.mkIf cfg.enable` (matching server pattern)
> - All home-manager modules use the same standardized pattern
> - Updated root CLAUDE.md with canonical module template
> - New modules/home-manager/CLAUDE.md
> - Updated modules/nixos/CLAUDE.md and modules/server/CLAUDE.md
> - Refreshed README.md with profile docs and structural accuracy
> - Updated parts/README.md and secrets/README.md
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves (6 parallel → 1 gate → 6 parallel)
> **Critical Path**: Module fixes → nix eval gate → Documentation → Final review

---

## Context

### Original Request
Unify the setup so patterns are the same across the whole project, then update/redo all documentation for both humans and AI.

### Interview Summary
**Key Discussions**:
- Server modules (`modules/server/`) are the "gold standard" — all 31+ modules follow identical `let cfg = config.server.<name>;` pattern with consistent config guards
- nixos modules use inline `config.<name>` references (no cfg binding) — inconsistent with server
- home-manager modules are mixed — some have cfg binding, some don't
- Documentation exists (6 files, ~735 lines) and is accurate, but missing home-manager CLAUDE.md and canonical module template

**User Decisions**:
- Namespace: Keep root-level for nixos/home-manager (`options.<name>`), server keeps `options.server.<name>` — intentional difference
- cfg binding: Standardize to server pattern everywhere
- File structure: Single file default, directory only when 3+ sub-modules
- Documentation: Full overhaul (all existing + create missing)
- Verification: `nix eval` per host
- Old plans: Leave untouched

**Research Findings**:
- ~22 nixos leaf modules need cfg binding added
- ~20 home-manager leaf modules need cfg binding added or standardized
- 5 nixos + 3 home-manager modules already have partial cfg binding — need completeness audit
- 29 home-manager sub-modules have NO enable options — skip entirely
- 3 nixos default.nix aggregators — skip entirely
- All 31+ server modules — already consistent, zero changes

### Metis Review
**Identified Gaps** (addressed):
- Cross-module references (config.user, config.sops.*) MUST NOT be replaced — scoped replacement rules added per task
- Installer host must be included in verification (10 hosts, not 9)
- Modules with `mkMerge` / nested `mkIf` need cfg binding WITHOUT restructuring conditional logic
- Sub-modules without enable options need explicit skip list
- `with lib;` standardization marked explicitly OUT OF SCOPE
- `mkOption` vs `mkEnableOption` differences marked OUT OF SCOPE

---

## Work Objectives

### Core Objective
Bring every module in the project to a consistent structural pattern (cfg binding + config guard) and ensure documentation accurately describes these patterns.

### Concrete Deliverables
- Every nixos leaf module uses `let cfg = config.<name>; in { ... }` pattern
- Every home-manager leaf module uses the same pattern
- 7 documentation files updated/created with current patterns and canonical templates
- All 10 nixosConfigurations pass `nix eval`

### Definition of Done
- [ ] `grep -rn "lib.mkIf config\." modules/nixos/ | grep -v "config\.user\|config\.sops\|config\.home-manager\|config\.smbmount\|config\.networking\|config\.services"` returns zero results for own-module inline refs
- [ ] Same grep check passes for modules/home-manager/
- [ ] `nix eval` succeeds for all 10 hosts (9 + installer)
- [ ] `nix fmt -- --check .` passes
- [ ] modules/home-manager/CLAUDE.md exists
- [ ] Root CLAUDE.md contains canonical module template

### Must Have
- Consistent `let cfg` binding in every leaf module with an enable option
- Consistent `lib.mkIf cfg.enable` config guard
- Cross-module references preserved exactly (config.user, config.sops.*, config.home-manager.*, etc.)
- All existing module behavior unchanged (zero functional diff)
- Documentation reflects the standardized patterns

### Must NOT Have (Guardrails)
- **DO NOT rename any options** — cfg is an alias, not a rename
- **DO NOT touch cross-module references** — `config.user`, `config.sops.*`, `config.home-manager.users.*`, `config.smbmount.*`, `config.networking.*`, `config.services.*` stay as-is
- **DO NOT restructure mkMerge / nested mkIf logic** — only add cfg binding and replace refs to the module's OWN namespace
- **DO NOT touch sub-modules without enable options** (neovim/*, zsh/*, hyprland/* sub-files, all default.nix aggregators)
- **DO NOT touch any server modules** — already standardized
- **DO NOT standardize `with lib;` vs explicit `lib.*`** — out of scope
- **DO NOT change `mkOption` to `mkEnableOption`** or vice versa — out of scope
- **DO NOT split or merge any files** — out of scope
- **DO NOT create documentation files beyond the 7 specified** — no per-host READMEs, no ARCHITECTURE.md, no CONTRIBUTING.md
- **DO NOT add emoji, ASCII art, or decorative elements to documentation**
- **DO NOT change module behavior** — if `nix eval` output changes, something is wrong

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO (NixOS flake — no unit test framework)
- **Automated tests**: None — verification is `nix eval` + `nix fmt` + pattern grep
- **Framework**: N/A

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Module fixes**: Use Bash — `nix eval`, grep for remaining inline patterns, `nix fmt --check`
- **Documentation**: Use Bash — verify file exists, check for required sections, cross-reference accuracy

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - module standardization, MAX PARALLEL):
├── Task 1: Fix modules/nixos/ root-level modules [quick]
├── Task 2: Fix modules/nixos/ subdirectory modules (hardware/, work/, hosted-services/) [quick]
├── Task 3: Fix modules/home-manager/cli/ modules [quick]
├── Task 4: Fix modules/home-manager/desktop/ modules [quick]
├── Task 5: Fix modules/home-manager/app/ + misc/ modules [quick]
└── Task 6: Audit already-partially-standardized modules for completeness [quick]

Wave 2 (After Wave 1 - verification gate):
└── Task 7: Cross-cutting verification (nix eval 10 hosts + grep + nix fmt) [quick]

Wave 3 (After Wave 2 - documentation overhaul, MAX PARALLEL):
├── Task 8: Update root CLAUDE.md with canonical module template [writing]
├── Task 9: Create modules/home-manager/CLAUDE.md [writing]
├── Task 10: Update modules/nixos/CLAUDE.md [writing]
├── Task 11: Update modules/server/CLAUDE.md [writing]
├── Task 12: Update README.md (refresh structure + profile docs) [writing]
└── Task 13: Update parts/README.md + secrets/README.md [writing]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 1-6 → Task 7 (gate) → Task 8-13 → F1-F4 → user okay
Parallel Speedup: ~65% faster than sequential
Max Concurrent: 6 (Waves 1 & 3)
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1-6 | - | 7 | 1 |
| 7 | 1-6 | 8-13 | 2 |
| 8-13 | 7 | F1-F4 | 3 |
| F1-F4 | 8-13 | user okay | FINAL |

### Agent Dispatch Summary

- **Wave 1**: 6 tasks → all `quick` (mechanical find-replace with scoped rules)
- **Wave 2**: 1 task → `quick` (verification commands)
- **Wave 3**: 6 tasks → all `writing` (documentation)
- **Wave FINAL**: 4 tasks → `oracle`, `unspecified-high` (×2), `deep`

---

## TODOs

- [x] 1. Standardize modules/nixos/ root-level modules

  **What to do**:
  - For EACH `.nix` file directly in `modules/nixos/` (NOT default.nix, NOT subdirectories):
    1. Check if file has `options.<name>.enable = lib.mkEnableOption` — if NO options block, SKIP the file
    2. If file already has `let cfg = config.<name>;`, verify all own-namespace refs use `cfg.` — fix any remaining inline refs
    3. If file lacks cfg binding: add `let cfg = config.<name>;` at the top of the function body
    4. Replace all `config.<name>.` references with `cfg.` — but ONLY for the module's OWN namespace
    5. Change config guard from `config = lib.mkIf config.<name>.enable` to `config = lib.mkIf cfg.enable`
    6. Run `nix fmt` on each changed file
  - **Target files** (non-exhaustive — discover full list via `ls modules/nixos/*.nix | grep -v default.nix`):
    gaming.nix, hyprland.nix, ollama.nix, syncthing.nix, tailscale.nix, security.nix, virtualization.nix, cosmic.nix, fonts.nix, general.nix, secrets.nix, distributed-builds.nix, docker.nix, flatpak.nix, stylix.nix, netbird-client.nix, and any others found
  - **Special cases**:
    - `security.nix`: Uses `mkMerge` with multiple `mkIf` blocks — add `let cfg = config.security;` but do NOT restructure the mkMerge. Inner guards become `cfg.enable` and `cfg.insecurePackages.enable`
    - `virtualization.nix`: Has nested sub-options (docker, podman, qemu) — `config.virtualization.docker.enable` becomes `cfg.docker.enable`. Cross-module refs like `config.user` stay unchanged
    - `gaming.nix`: Similar nested structure — `config.gaming.steam.enable` becomes `cfg.steam.enable`
    - `distributed-builds.nix`: Already has `let cfg` — verify completeness

  **Must NOT do**:
  - Touch `modules/nixos/default.nix` (import aggregator — no options)
  - Replace cross-module references: `config.user`, `config.sops.*`, `config.home-manager.*`, `config.smbmount.*`, `config.networking.*`, `config.services.*`, `config.boot.*`, `config.programs.*`, `config.hardware.*`, `config.systemd.*`, `config.nix.*`, `config.environment.*`, `config.xdg.*`, `config.i18n.*`, `config.time.*`, `config.console.*`, `config.system.*`, `config.virtualisation.*` (NixOS system options, not module options)
  - Restructure any `mkMerge` or nested `mkIf` conditional logic
  - Change `mkOption` to `mkEnableOption` or vice versa
  - Rename any options
  - Standardize `with lib;` usage

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical find-replace with clear rules — no creative judgment needed
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References** (gold standard to follow):
  - `modules/server/caddy.nix` — Canonical pattern: `let cfg = config.server.caddy; in { options.server.caddy = { ... }; config = lib.mkIf cfg.enable { ... }; }`. Copy this structure but with root-level namespace (`config.<name>` instead of `config.server.<name>`)
  - `modules/server/mealie.nix` — Another clean example with port/domain options

  **Files to modify** (discover full list at runtime):
  - `modules/nixos/*.nix` (all root-level .nix files except default.nix)

  **Cross-module refs to PRESERVE** (DO NOT replace these):
  - `config.user` — references the user name from host config
  - `config.sops.*` — sops-nix secret references
  - `config.home-manager.*` — home-manager system integration
  - `config.smbmount.*` — NAS mount module reference (used in secrets.nix)
  - Any `config.<system-option>` that is NOT the current module's own namespace

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: All root nixos modules have cfg binding
    Tool: Bash
    Preconditions: All root-level .nix files in modules/nixos/ (excluding default.nix) have been modified
    Steps:
      1. Run: for f in modules/nixos/*.nix; do [[ "$(basename $f)" == "default.nix" ]] && continue; grep -L "let" "$f" | grep -L "cfg" "$f"; done
      2. Verify: no files are listed (all have "let" and "cfg")
      3. Run: grep -rn "lib.mkIf config\." modules/nixos/*.nix | grep -v default.nix
      4. Filter output to exclude known cross-module refs (config.user, config.sops, etc.)
      5. Verify: zero remaining own-module inline config refs
    Expected Result: All files have cfg binding, no own-module inline refs remain
    Failure Indicators: Any file listed in step 1, or any own-module ref in step 4
    Evidence: .sisyphus/evidence/task-1-nixos-root-cfg-check.txt

  Scenario: Cross-module refs preserved
    Tool: Bash
    Preconditions: Module files have been modified
    Steps:
      1. Run: grep -rn "config\.user" modules/nixos/*.nix
      2. Verify: all expected cross-module refs still present (not replaced with cfg.user)
      3. Run: grep -rn "config\.sops" modules/nixos/*.nix
      4. Verify: sops refs intact
    Expected Result: Cross-module refs unchanged from before modification
    Failure Indicators: Any `cfg.user`, `cfg.sops`, `cfg.home-manager` in output
    Evidence: .sisyphus/evidence/task-1-cross-ref-check.txt
  ```

  **Commit**: YES (groups with Tasks 2-6 in one Wave 1 commit)
  - Message: `refactor(modules): standardize cfg binding and config guards across nixos and home-manager modules`
  - Files: `modules/nixos/*.nix` (changed files only)
  - Pre-commit: grep check for remaining inline refs

- [x] 2. Standardize modules/nixos/ subdirectory modules (hardware/, work/, hosted-services/)

  **What to do**:
  - Apply the SAME standardization pattern as Task 1 to all leaf modules in subdirectories:
    - `modules/nixos/hardware/*.nix` (nas.nix, nvidia.nix, audio.nix, bluetooth.nix, networking.nix, etc.)
    - `modules/nixos/work/*.nix` and `modules/nixos/work/default.nix` (if it has options)
    - `modules/nixos/hosted-services/*.nix` (n8n.nix, open-webui.nix, etc.)
  - For each file: check for enable option → add/verify cfg binding → replace own-namespace refs → verify cross-module refs preserved
  - **Special cases**:
    - `hardware/nas.nix`: Already has `let cfg` — verify completeness
    - `hosted-services/n8n.nix`, `hosted-services/open-webui.nix`: Already have `let cfg` — verify completeness
    - `work/default.nix`: Has parent-child cascade (`work.communication.enable = lib.mkDefault true;`) — these are SETTING operations inside `config = lib.mkIf cfg.enable { ... }`, so they use the option name NOT cfg. Only READING config values should use cfg. The `lib.mkIf cfg.enable` guard at top is the only change needed.
    - Subdirectory `default.nix` files that are pure import aggregators: SKIP

  **Must NOT do**:
  - Same guardrails as Task 1
  - Touch aggregator default.nix files without options
  - Change work/ parent-child cascade logic — setting `work.communication.enable = lib.mkDefault true;` inside a config block is setting an OPTION, not reading it, so it stays as the option name

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Same mechanical pattern as Task 1, smaller file set
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/server/caddy.nix` — Gold standard pattern
  - Task 1's rules and special case handling — same rules apply

  **Files to modify** (discover at runtime):
  - `modules/nixos/hardware/*.nix` (all except aggregator default.nix)
  - `modules/nixos/work/*.nix` (all except pure aggregator)
  - `modules/nixos/hosted-services/*.nix` (all except pure aggregator)

  **Cross-module refs to PRESERVE**: Same list as Task 1

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: All subdirectory modules have cfg binding
    Tool: Bash
    Preconditions: All leaf .nix files in hardware/, work/, hosted-services/ have been checked/modified
    Steps:
      1. Run: find modules/nixos/hardware modules/nixos/work modules/nixos/hosted-services -name "*.nix" -exec grep -L "let" {} \; 2>/dev/null
      2. For each file listed: check if it has options block — if no options, it's correctly skipped
      3. For files WITH options: verify they now have cfg binding
      4. Run: grep -rn "lib.mkIf config\." modules/nixos/hardware/ modules/nixos/work/ modules/nixos/hosted-services/ | grep -v default.nix
      5. Filter for own-module refs only
    Expected Result: All leaf modules with options have cfg binding
    Failure Indicators: Any leaf module with options but no cfg binding
    Evidence: .sisyphus/evidence/task-2-nixos-subdir-cfg-check.txt

  Scenario: work/ parent-child cascade intact
    Tool: Bash
    Preconditions: work/default.nix has been modified
    Steps:
      1. Run: grep "mkDefault" modules/nixos/work/default.nix
      2. Verify: child enable settings still use option names (not cfg)
      3. Verify: only the top-level mkIf guard uses cfg.enable
    Expected Result: Pattern `lib.mkIf cfg.enable { work.communication.enable = lib.mkDefault true; }` preserved
    Failure Indicators: Any child enable using `cfg.communication.enable` instead of `work.communication.enable`
    Evidence: .sisyphus/evidence/task-2-work-cascade-check.txt
  ```

  **Commit**: YES (groups with Wave 1 commit)
  - Message: (same as Task 1 — single commit for all Wave 1)
  - Files: `modules/nixos/hardware/*.nix`, `modules/nixos/work/*.nix`, `modules/nixos/hosted-services/*.nix`

- [x] 3. Standardize modules/home-manager/cli/ modules

  **What to do**:
  - Apply cfg binding standardization to all leaf modules in `modules/home-manager/cli/`:
    - Top-level .nix files: `git.nix`, `ghostty.nix`, `tmux.nix`, `lazygit.nix`, `direnv.nix`, `prompt.nix`, etc.
    - Directory parent files: `neovim/default.nix`, `zsh/default.nix` — these have enable options
    - **SKIP** sub-module files: `neovim/lsp.nix`, `neovim/cmp.nix`, `neovim/treesitter.nix`, `zsh/zsh.nix`, `zsh/eza.nix`, etc. — these have NO enable options (they're config-only, imported by the parent)
  - For each file WITH an enable option:
    1. Add `let cfg = config.<name>;` (e.g., `let cfg = config.git;`)
    2. Replace `config.<name>.enable` with `cfg.enable` in mkIf guards
    3. Replace any other `config.<name>.X` reads with `cfg.X`
    4. Preserve all `config.home-manager.users.${config.user}` wrappers — these are cross-module refs
    5. Run `nix fmt` on changed files
  - **Special cases**:
    - `ghostty.nix`: Already has `let cfg = config.ghostty;` — verify completeness
    - `tmux.nix`: Already has `let cfg` — verify completeness
    - `neovim/default.nix`: Uses `lib.mkOption { type = lib.types.bool; }` instead of `mkEnableOption` — leave this as-is (out of scope), just add/verify cfg binding
    - `zsh/default.nix`: Check if has cfg binding, add if missing

  **Must NOT do**:
  - Touch sub-module files without enable options (neovim/lsp.nix, neovim/cmp.nix, etc.)
  - Touch default.nix aggregators that only import other files
  - Replace `config.home-manager.users.${config.user}` — this is a cross-module ref
  - Replace `config.user` — cross-module ref
  - Change `mkOption` to `mkEnableOption` in neovim/default.nix

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical pattern application
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/server/caddy.nix` — Gold standard pattern
  - `modules/home-manager/cli/ghostty.nix` — Already has correct cfg pattern for home-manager context (includes `config.home-manager.users.${config.user}` wrapper)

  **Files to modify**: `modules/home-manager/cli/*.nix` + `modules/home-manager/cli/*/default.nix` (parent files only)
  **Files to SKIP**: All sub-module files inside neovim/, zsh/, and any other subdirectories that lack enable options

  **Cross-module refs to PRESERVE**:
  - `config.home-manager.users.${config.user}` — home-manager user wrapper
  - `config.user` — username reference
  - `config.sops.*` — if present
  - `inputs.*` — flake input references

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: All cli leaf modules with options have cfg binding
    Tool: Bash
    Preconditions: All cli/ leaf modules with enable options have been modified
    Steps:
      1. List all .nix files in modules/home-manager/cli/ that contain "mkEnableOption\|mkOption.*bool"
      2. For each: verify it contains "let" and "cfg = config."
      3. Verify no own-module inline config refs remain in mkIf guards
    Expected Result: Every file with an enable option has cfg binding
    Failure Indicators: File with enable option but no cfg binding
    Evidence: .sisyphus/evidence/task-3-hm-cli-cfg-check.txt

  Scenario: Sub-modules untouched
    Tool: Bash
    Preconditions: Task complete
    Steps:
      1. Run: git diff --name-only -- modules/home-manager/cli/neovim/
      2. Verify: only default.nix appears (if it was modified), NOT lsp.nix, cmp.nix, etc.
      3. Same check for zsh/ subdirectory
    Expected Result: Sub-module files unchanged
    Failure Indicators: Any sub-module file in the diff
    Evidence: .sisyphus/evidence/task-3-submodule-untouched-check.txt
  ```

  **Commit**: YES (groups with Wave 1 commit)

- [x] 4. Standardize modules/home-manager/desktop/ modules

  **What to do**:
  - Apply cfg binding standardization to leaf modules in `modules/home-manager/desktop/`:
    - Directory parent files: `hyprland/default.nix`, `waybar/default.nix`, `rofi/default.nix`, `swaync/default.nix`, etc. — check each for enable options
    - Top-level .nix files if any
    - **SKIP** sub-module files inside directories that have NO enable options (e.g., hyprland/keybindings.nix, hyprland/packages.nix, hyprland/rules.nix, waybar/style.nix, etc.)
  - Same pattern as Tasks 1-3: add cfg binding, replace own-namespace refs, preserve cross-module refs
  - **Special case**:
    - `hyprland/default.nix`: Large file (187 lines) with activation hooks and complex config — be careful to only replace `config.hyprland.` (or whatever its namespace is) with `cfg.`, not any other config refs. May have `config.stylix`, `config.home-manager`, etc.

  **Must NOT do**:
  - Touch hyprland sub-modules (keybindings.nix, packages.nix, rules.nix, etc.)
  - Touch waybar/rofi/swaync sub-modules without enable options
  - Replace `config.stylix.*`, `config.home-manager.*`, `config.user`, or other cross-module refs

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical pattern application
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/home-manager/cli/ghostty.nix` — Clean home-manager module with cfg binding
  - `modules/server/caddy.nix` — Gold standard structure

  **Files to modify**: `modules/home-manager/desktop/*/default.nix` (parent files with enable options only)
  **Files to SKIP**: All sub-module config files within each desktop directory

  **Cross-module refs to PRESERVE**:
  - `config.home-manager.users.${config.user}`
  - `config.user`, `config.stylix.*`, `config.sops.*`
  - Any `config.<other-module>.*` references

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Desktop parent modules have cfg binding
    Tool: Bash
    Preconditions: All desktop/ parent files with enable options modified
    Steps:
      1. Find all default.nix files in modules/home-manager/desktop/*/
      2. For each that has mkEnableOption: verify cfg binding exists
      3. Grep for remaining inline own-module config refs
    Expected Result: All parent modules standardized
    Failure Indicators: Parent module with enable option but no cfg binding
    Evidence: .sisyphus/evidence/task-4-hm-desktop-cfg-check.txt

  Scenario: Desktop sub-modules untouched
    Tool: Bash
    Steps:
      1. Run: git diff --name-only -- modules/home-manager/desktop/
      2. Verify: only */default.nix files appear, not sub-modules
    Expected Result: Sub-module files unchanged
    Evidence: .sisyphus/evidence/task-4-desktop-submodule-check.txt
  ```

  **Commit**: YES (groups with Wave 1 commit)

- [x] 5. Standardize modules/home-manager/app/ + misc/ modules

  **What to do**:
  - Apply cfg binding standardization to all leaf modules in:
    - `modules/home-manager/app/*.nix` (discord.nix, spotify.nix, etc.)
    - `modules/home-manager/misc/*.nix` (zen-browser.nix, thunar.nix, etc.)
  - Same pattern as previous tasks
  - **Special cases**:
    - `web-apps.nix` (if in app/ or misc/): Already has `let cfg` — verify completeness
    - `zen-browser.nix`: Has mixed system + home-manager config — only replace refs to its OWN namespace, preserve all cross-module refs
    - Some modules may reference `inputs.zen-browser.*` or similar flake inputs — these are NOT config refs, leave them

  **Must NOT do**:
  - Same guardrails as all previous tasks
  - Replace `inputs.*` references (flake inputs, not config)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical pattern application, small file set
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 4, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/home-manager/cli/ghostty.nix` — Clean home-manager cfg pattern
  - `modules/server/caddy.nix` — Gold standard

  **Files to modify**: All .nix files in `modules/home-manager/app/` and `modules/home-manager/misc/` (excluding any aggregator default.nix)
  **Files to SKIP**: Aggregator files without options

  **Cross-module refs to PRESERVE**: Same as Tasks 3-4 + `inputs.*`

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: All app + misc modules have cfg binding
    Tool: Bash
    Steps:
      1. List all .nix files with mkEnableOption in modules/home-manager/app/ and modules/home-manager/misc/
      2. Verify each has cfg binding
      3. Grep for remaining inline own-module config refs
    Expected Result: All modules with enable options standardized
    Evidence: .sisyphus/evidence/task-5-hm-app-misc-cfg-check.txt

  Scenario: inputs.* references preserved
    Tool: Bash
    Steps:
      1. Run: grep -rn "inputs\." modules/home-manager/app/ modules/home-manager/misc/
      2. Verify all flake input references are intact (not accidentally replaced)
    Expected Result: All inputs.* refs unchanged
    Evidence: .sisyphus/evidence/task-5-inputs-preserved.txt
  ```

  **Commit**: YES (groups with Wave 1 commit)

- [x] 6. Audit already-partially-standardized modules for completeness

  **What to do**:
  - 8 modules already have `let cfg` binding but may have INCOMPLETE migration (leftover inline refs alongside the binding). Check each:
    - **nixos**: `distributed-builds.nix`, `init-net.nix`, `hardware/nas.nix`, `hosted-services/n8n.nix`, `hosted-services/open-webui.nix`
    - **home-manager**: `cli/tmux.nix`, `cli/ghostty.nix`, `misc/web-apps.nix` (or wherever web-apps lives)
  - For each file:
    1. Verify `let cfg = config.<name>;` exists
    2. Search for ANY remaining `config.<name>.` references (where `<name>` is the module's own namespace)
    3. If found: replace with `cfg.`
    4. Verify config guard uses `cfg.enable` not `config.<name>.enable`
    5. Run `nix fmt`

  **Must NOT do**:
  - Same guardrails as all other tasks

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small file set, verification + minor fixes
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 4, 5)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:

  **Files to audit** (exact list):
  - `modules/nixos/distributed-builds.nix`
  - `modules/nixos/init-net.nix`
  - `modules/nixos/hardware/nas.nix`
  - `modules/nixos/hosted-services/n8n.nix`
  - `modules/nixos/hosted-services/open-webui.nix`
  - `modules/home-manager/cli/tmux.nix`
  - `modules/home-manager/cli/ghostty.nix`
  - `modules/home-manager/misc/web-apps.nix` (verify path at runtime)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: All 8 pre-existing cfg modules are fully migrated
    Tool: Bash
    Steps:
      1. For each of the 8 files: grep for "config\.<module-namespace>\." (the module's own namespace)
      2. Verify: zero remaining own-namespace inline refs in any of the 8 files
      3. Verify: each file's mkIf guard uses cfg.enable
    Expected Result: All 8 modules fully consistent — no partial migrations
    Evidence: .sisyphus/evidence/task-6-partial-audit.txt

  Scenario: No regressions from "fixing" already-correct modules
    Tool: Bash
    Steps:
      1. For modules that were already correct: verify git diff is empty (no unnecessary changes)
      2. For modules that needed fixes: verify only the inline ref replacements changed
    Expected Result: Minimal diff — only necessary changes
    Evidence: .sisyphus/evidence/task-6-minimal-diff.txt
  ```

  **Commit**: YES (groups with Wave 1 commit)

- [x] 7. Cross-cutting verification gate (nix eval + grep + fmt)

  **What to do**:
  - Run `nix eval` on ALL 10 nixosConfigurations to verify nothing is broken:
    ```bash
    nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.vnpc-21.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.spiders.config.system.build.toplevel.drvPath
    nix eval .#nixosConfigurations.installer.config.system.build.toplevel.drvPath
    ```
  - Run `nix fmt -- --check .` to verify formatting
  - Run pattern verification greps to confirm standardization is complete:
    ```bash
    # Check nixos modules for remaining inline config guards (own-module only)
    grep -rn "lib.mkIf config\." modules/nixos/ --include="*.nix" | grep -v "default.nix"
    # Review output — should only contain cross-module refs, not own-module inline refs

    # Same for home-manager
    grep -rn "lib.mkIf config\." modules/home-manager/ --include="*.nix" | grep -v "default.nix"
    ```
  - If ANY `nix eval` fails: identify the broken module, report the error, and note which Task (1-6) needs a fix
  - If grep finds own-module inline refs: report which files still need attention
  - If `nix fmt` fails: run `nix fmt` to fix and note the files

  **Must NOT do**:
  - Fix modules yourself — report failures back for the appropriate Wave 1 task to fix
  - Skip any host in the eval check

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Running verification commands and reporting results
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sequential gate)
  - **Blocks**: Tasks 8-13
  - **Blocked By**: Tasks 1-6

  **References**:
  - All 10 host names from `parts/hosts.nix`
  - Grep patterns from Success Criteria section of this plan

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: All 10 hosts evaluate successfully
    Tool: Bash
    Preconditions: All Wave 1 tasks complete
    Steps:
      1. Run nix eval for each of the 10 hosts listed above
      2. Capture exit code and output for each
      3. All must return a valid /nix/store path and exit 0
    Expected Result: 10/10 hosts pass evaluation
    Failure Indicators: Any non-zero exit code or error message
    Evidence: .sisyphus/evidence/task-7-nix-eval-all-hosts.txt

  Scenario: Formatting is clean
    Tool: Bash
    Steps:
      1. Run: nix fmt -- --check .
      2. Capture exit code
    Expected Result: Exit code 0 (all files formatted)
    Failure Indicators: Non-zero exit code listing unformatted files
    Evidence: .sisyphus/evidence/task-7-nix-fmt-check.txt

  Scenario: No remaining own-module inline config refs
    Tool: Bash
    Steps:
      1. Run grep commands listed above for both modules/nixos/ and modules/home-manager/
      2. Review each match — classify as cross-module (OK) or own-module (FAIL)
      3. Report any own-module refs that should have been replaced
    Expected Result: Zero own-module inline refs remaining
    Failure Indicators: Any own-module inline config ref in grep output
    Evidence: .sisyphus/evidence/task-7-pattern-grep.txt
  ```

  **Commit**: NO (verification only — no file changes. If nix fmt needed, that's a fix-up before committing Wave 1)

- [ ] 8. Update root CLAUDE.md with canonical module template

  **What to do**:
  - Rewrite `CLAUDE.md` (currently 51 lines) to be comprehensive but concise. Must include:
    1. **Architecture** section (keep existing, verify accuracy)
    2. **Hosts** section (keep existing, verify all hosts listed including nero)
    3. **Commands** section (keep existing, verify accuracy)
    4. **Rules** section (keep existing, add canonical module pattern rule)
    5. **NEW: Canonical Module Templates** section showing:
       - NixOS module template (with `let cfg = config.<name>;`)
       - Home-manager module template (with `config.home-manager.users.${config.user}` wrapper)
       - Server module template (with `let cfg = config.server.<name>;`)
       - File structure rule: "Single file default. Directory with default.nix only when 3+ sub-modules needed."
    6. **External flake-sourced modules** (keep existing, verify accuracy)
    7. **Gotchas** section (keep existing, add pattern-related gotchas)
  - Keep it under 100 lines — CLAUDE.md should be dense context, not a tutorial
  - Verify ALL file paths and host references are accurate against actual project state

  **Must NOT do**:
  - Add emoji or decorative elements
  - Make it longer than 100 lines
  - Include implementation details that belong in sub-directory CLAUDE.md files
  - Remove existing accurate information

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation authoring requiring accurate technical content
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 11, 12, 13)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 7

  **References**:

  **Current file**: `CLAUDE.md` (51 lines) — read for existing content to preserve/update
  **Pattern source**: `modules/server/caddy.nix` — gold standard module to derive template from
  **HM pattern source**: `modules/home-manager/cli/ghostty.nix` — home-manager module template source
  **Accuracy checks**: `parts/hosts.nix` (host list), `flake.nix` (inputs), `justfile` (commands)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: CLAUDE.md contains canonical module templates
    Tool: Bash
    Steps:
      1. Run: grep -c "let cfg" CLAUDE.md
      2. Verify: at least 3 matches (one per template: nixos, home-manager, server)
      3. Run: grep "config.home-manager.users" CLAUDE.md
      4. Verify: home-manager template includes the wrapper pattern
    Expected Result: All 3 canonical templates present
    Evidence: .sisyphus/evidence/task-8-claude-md-templates.txt

  Scenario: All referenced paths exist
    Tool: Bash
    Steps:
      1. Extract all file paths from CLAUDE.md
      2. Verify each path exists in the project
    Expected Result: Zero broken path references
    Evidence: .sisyphus/evidence/task-8-claude-md-paths.txt

  Scenario: Under 100 lines
    Tool: Bash
    Steps:
      1. Run: wc -l CLAUDE.md
    Expected Result: Line count <= 100
    Evidence: .sisyphus/evidence/task-8-claude-md-linecount.txt
  ```

  **Commit**: YES (groups with Tasks 9-13 in one Wave 3 commit)
  - Message: `docs: update all documentation with canonical module patterns and refresh content`

- [ ] 9. Create modules/home-manager/CLAUDE.md

  **What to do**:
  - Create NEW file `modules/home-manager/CLAUDE.md` following the style of existing `modules/nixos/CLAUDE.md` (34 lines) and `modules/server/CLAUDE.md` (65 lines)
  - Must include:
    1. Purpose of home-manager modules (user-level config for desktops)
    2. Directory structure: `cli/`, `desktop/`, `app/`, `misc/` — what each contains
    3. Canonical module template for home-manager (with `config.home-manager.users.${config.user}` wrapper)
    4. Rules: cfg binding, config guard, when to use directory vs single file, what NOT to touch in sub-modules
    5. How modules reference packages (`pkgs`, `pkgs-unstable`, `inputs.*`)
    6. Relationship to nixos modules (system vs user level split)
  - Keep it 30-60 lines — match the density of sibling CLAUDE.md files

  **Must NOT do**:
  - Add emoji
  - Exceed 60 lines
  - Duplicate content from root CLAUDE.md

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: New documentation file creation
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 10, 11, 12, 13)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 7

  **References**:

  **Style references** (match these):
  - `modules/nixos/CLAUDE.md` (34 lines) — sibling file for system modules
  - `modules/server/CLAUDE.md` (65 lines) — sibling file for server modules

  **Content sources**:
  - `modules/home-manager/default.nix` — import structure showing directory organization
  - `modules/home-manager/cli/ghostty.nix` — canonical module pattern to document
  - `modules/home-manager/desktop/hyprland/default.nix` — complex module example
  - `modules/home-manager/misc/zen-browser.nix` — mixed system+HM example

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: File exists and has required sections
    Tool: Bash
    Steps:
      1. Verify: modules/home-manager/CLAUDE.md exists
      2. Run: grep -c "cli/\|desktop/\|app/\|misc/" modules/home-manager/CLAUDE.md
      3. Verify: all 4 subdirectories mentioned
      4. Run: grep "let cfg" modules/home-manager/CLAUDE.md
      5. Verify: canonical template present
      6. Run: wc -l modules/home-manager/CLAUDE.md
      7. Verify: 30-60 lines
    Expected Result: File exists, covers all sections, correct length
    Evidence: .sisyphus/evidence/task-9-hm-claude-md.txt

  Scenario: No content duplication with root CLAUDE.md
    Tool: Bash
    Steps:
      1. Compare key sections — home-manager CLAUDE.md should reference root for architecture, not repeat it
    Expected Result: Focused on home-manager specifics, not project-wide info
    Evidence: .sisyphus/evidence/task-9-no-duplication.txt
  ```

  **Commit**: YES (groups with Wave 3 commit)

- [ ] 10. Update modules/nixos/CLAUDE.md

  **What to do**:
  - Update existing `modules/nixos/CLAUDE.md` (currently 34 lines) to reflect the standardized patterns:
    1. Add/update canonical nixos module template showing `let cfg = config.<name>;` pattern
    2. Document the file structure rule (single file default, directory only with 3+ sub-modules)
    3. List subdirectory purposes: `hardware/`, `work/`, `hosted-services/`
    4. Document cross-module ref rules (what NOT to replace when editing modules)
    5. Verify all referenced modules/paths still exist
    6. Keep existing accurate content (module layers, desktop environments, theming info)
  - Stay under 50 lines

  **Must NOT do**:
  - Remove existing accurate information
  - Duplicate root CLAUDE.md content
  - Add emoji

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation update
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9, 11, 12, 13)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 7

  **References**:
  - Current file: `modules/nixos/CLAUDE.md` (34 lines)
  - Pattern source: `modules/server/CLAUDE.md` (65 lines) — more comprehensive, use as quality benchmark
  - Module examples: `modules/nixos/gaming.nix`, `modules/nixos/security.nix` (after standardization)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Updated content with canonical template
    Tool: Bash
    Steps:
      1. Verify: grep "let cfg" modules/nixos/CLAUDE.md returns match
      2. Verify: grep "hardware/\|work/\|hosted-services/" modules/nixos/CLAUDE.md — all subdirs documented
      3. Verify: wc -l modules/nixos/CLAUDE.md — under 50 lines
      4. Verify: all referenced file paths exist
    Expected Result: Template present, all subdirs documented, concise
    Evidence: .sisyphus/evidence/task-10-nixos-claude-md.txt
  ```

  **Commit**: YES (groups with Wave 3 commit)

- [ ] 11. Update modules/server/CLAUDE.md

  **What to do**:
  - Update existing `modules/server/CLAUDE.md` (currently 65 lines) to:
    1. Verify canonical template matches what server modules actually use (should already be accurate)
    2. Update the server assignment table if any services moved between servers
    3. Verify all referenced modules/paths still exist (especially check for second-brain, nero)
    4. Add the file structure rule (single file only — servers never use directories)
    5. Document the `options.server.<name>` namespace convention explicitly
    6. Keep the sops secrets pattern documentation (already good)
  - Stay under 70 lines

  **Must NOT do**:
  - Remove existing accurate information
  - Duplicate root CLAUDE.md content
  - Add emoji

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation update
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9, 10, 12, 13)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 7

  **References**:
  - Current file: `modules/server/CLAUDE.md` (65 lines)
  - Server module list: `modules/server/default.nix` — verify all modules documented
  - Host assignments: `hosts/pulse/default.nix`, `hosts/sugar/default.nix`, `hosts/byob/default.nix`, etc.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Server CLAUDE.md accurate and complete
    Tool: Bash
    Steps:
      1. Compare module list in CLAUDE.md vs actual .nix files in modules/server/
      2. Verify: all modules mentioned, no stale references
      3. Verify: server assignment table matches host default.nix files
      4. Verify: wc -l under 70 lines
    Expected Result: Accurate, complete, concise
    Evidence: .sisyphus/evidence/task-11-server-claude-md.txt
  ```

  **Commit**: YES (groups with Wave 3 commit)

- [ ] 12. Update README.md (refresh structure + profile docs)

  **What to do**:
  - Update existing `README.md` (currently 403 lines) to:
    1. Verify host table is complete (check nero is listed, check all server roles are current)
    2. Add **Profile System Documentation** section explaining:
       - What each profile does (base.nix, laptop.nix, desktop.nix, workstation.nix)
       - The inheritance chain (base → desktop → laptop/workstation)
       - How profiles relate to modules (profiles ENABLE modules)
       - hardware/ profiles (nvidia.nix, etc.)
    3. Update repository structure tree if any paths changed
    4. Update "Key Services" column in server table to match current service deployments
    5. Verify all code examples are syntactically valid
    6. Fix any inaccuracies found during research (second-brain references, nero listing)
  - The README is already comprehensive — this is a REFRESH, not a rewrite
  - Keep total length reasonable (under 500 lines)

  **Must NOT do**:
  - Rewrite from scratch — preserve existing good content
  - Add emoji or decorative elements
  - Add sections that belong in sub-directory docs (module internals, etc.)

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation refresh with accuracy verification
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9, 10, 11, 13)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 7

  **References**:
  - Current file: `README.md` (403 lines)
  - Profile files: `profiles/base.nix`, `profiles/laptop.nix`, `profiles/desktop.nix`, `profiles/workstation.nix`
  - Host configs: All `hosts/*/default.nix` for verifying host table accuracy
  - Server modules: `modules/server/default.nix` for verifying service listings

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: All hosts in README table
    Tool: Bash
    Steps:
      1. Extract host names from README.md tables
      2. Compare against: ls hosts/
      3. Verify: every host directory has a corresponding entry (except installer if intentionally excluded from main table)
    Expected Result: Host tables complete
    Evidence: .sisyphus/evidence/task-12-readme-hosts.txt

  Scenario: Profile documentation section exists
    Tool: Bash
    Steps:
      1. Run: grep -c "base.nix\|laptop.nix\|desktop.nix\|workstation.nix" README.md
      2. Verify: all 4 profiles mentioned in a documentation context (not just directory listing)
      3. Run: grep "Profile" README.md | head -5
      4. Verify: dedicated profile documentation section exists
    Expected Result: Profiles documented with inheritance explanation
    Evidence: .sisyphus/evidence/task-12-readme-profiles.txt

  Scenario: All referenced paths exist
    Tool: Bash
    Steps:
      1. Extract file paths from README.md repository structure tree
      2. Verify each path exists
    Expected Result: Zero broken references
    Evidence: .sisyphus/evidence/task-12-readme-paths.txt
  ```

  **Commit**: YES (groups with Wave 3 commit)

- [ ] 13. Update parts/README.md + secrets/README.md

  **What to do**:
  - **parts/README.md** (currently 42 lines):
    1. Verify all file descriptions match current behavior (lib.nix, hosts.nix, deploy.nix, dev.nix)
    2. Update "Adding a new host" instructions if they reference outdated patterns
    3. Verify mkHost/mkServer descriptions match actual implementations in parts/lib.nix
    4. Add any missing parts/ files if new ones were added since last update
  - **secrets/README.md** (currently 140 lines):
    1. Verify SOPS key group descriptions match `.sops.yaml`
    2. Verify per-host secret file listings match actual `secrets/*.yaml` files (including nero.yaml)
    3. Update any stale examples or instructions
    4. Verify command examples match current `justfile` targets
  - Both files are already thorough — this is a VERIFICATION pass with minor fixes

  **Must NOT do**:
  - Rewrite from scratch
  - Add emoji
  - Create new README files beyond these two

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Documentation verification and minor updates
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9, 10, 11, 12)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 7

  **References**:
  - Current files: `parts/README.md` (42 lines), `secrets/README.md` (140 lines)
  - Source of truth: `parts/lib.nix`, `parts/hosts.nix`, `parts/deploy.nix`, `.sops.yaml`, `justfile`
  - Verify against: `ls secrets/*.yaml`, `ls parts/*.nix`

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: parts/README.md matches actual parts/ files
    Tool: Bash
    Steps:
      1. List all .nix files in parts/
      2. Verify each is mentioned in parts/README.md
      3. Verify mkHost/mkServer descriptions match parts/lib.nix
    Expected Result: README accurately describes all parts/ files
    Evidence: .sisyphus/evidence/task-13-parts-readme.txt

  Scenario: secrets/README.md matches actual secrets structure
    Tool: Bash
    Steps:
      1. List all .yaml files in secrets/
      2. Verify each is mentioned in secrets/README.md
      3. Compare key groups in .sops.yaml with descriptions in README
    Expected Result: README accurately describes all secrets and key groups
    Evidence: .sisyphus/evidence/task-13-secrets-readme.txt
  ```

  **Commit**: YES (groups with Wave 3 commit)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (grep for cfg patterns, check file existence). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `nix fmt -- --check .` + `nix eval` on all 10 hosts. Review all changed module files for: broken cross-module refs (config.user → cfg.user would be BAD), inconsistent cfg binding placement, remaining inline `config.<namespace>.enable` patterns. Check that no module behavior changed.
  Output: `Fmt [PASS/FAIL] | Eval [N/10 pass] | Pattern Check [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. For each documentation file: verify all code examples are syntactically valid Nix, verify all referenced file paths exist, verify canonical template matches actual module patterns. For modules: spot-check 5 random nixos + 5 random home-manager modules for correct pattern application. Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Docs [N/N accurate] | Modules Spot-Check [N/N correct] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance: no server modules touched, no option renames, no mkMerge restructuring, no `with lib;` changes. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Scope Creep [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

| After | Commit Message | Files | Pre-commit Check |
|-------|---------------|-------|-----------------|
| Wave 1 (all module fixes) | `refactor(modules): standardize cfg binding and config guards across nixos and home-manager modules` | All changed modules in modules/nixos/ and modules/home-manager/ | `nix eval` all 10 hosts + `nix fmt` |
| Wave 3 (all documentation) | `docs: update all documentation with canonical module patterns and refresh content` | All .md files changed/created | Verify files exist, paths referenced are valid |

---

## Success Criteria

### Verification Commands
```bash
# All 10 hosts evaluate successfully
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.vnpc-21.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.spiders.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.installer.config.system.build.toplevel.drvPath

# Formatting passes
nix fmt -- --check .

# No remaining inline config guards for own-module refs in nixos
grep -rn "lib.mkIf config\." modules/nixos/ --include="*.nix" | grep -v "default.nix" | grep -v "config\.user\|config\.sops\|config\.home-manager\|config\.smbmount\|config\.networking\|config\.services\|config\.boot\|config\.programs\|config\.hardware\|config\.systemd\|config\.security\|config\.environment\|config\.nix\|config\.xdg\|config\.lib\|config\.i18n\|config\.time\|config\.console\|config\.system\|config\.virtualisation"
# Expected: zero results (or only legitimate cross-module refs)

# Same for home-manager
grep -rn "lib.mkIf config\." modules/home-manager/ --include="*.nix" | grep -v "default.nix" | grep -v "config\.user\|config\.sops\|config\.home-manager\|config\.networking\|config\.services"
# Expected: zero results (or only legitimate cross-module refs)
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All 10 `nix eval` pass
- [ ] `nix fmt` passes
- [ ] modules/home-manager/CLAUDE.md exists
- [ ] Root CLAUDE.md contains canonical module template section
- [ ] README.md includes profile documentation section
