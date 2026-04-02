# Station → Arch Linux Migration

## TL;DR

> **Quick Summary**: Migrate the "station" desktop from NixOS to Arch Linux while preserving the entire desktop environment (Hyprland, 50+ HM modules, Nord theming) via standalone home-manager. Refactor HM modules to work in both NixOS-integrated and standalone modes. Document Arch system setup as a runbook.
> 
> **Deliverables**:
> - New `homeConfigurations` flake output for standalone home-manager
> - HM module compatibility layer (all 50+ modules work in both NixOS and standalone mode)
> - Complete station-arch host config with all module enables and station-specific overrides
> - Standalone stylix theming (Nord, `homeModules.stylix`)
> - Standalone SOPS secrets (`homeManagerModules.sops`)
> - Nix daemon + build server config for Arch
> - Arch system setup guide (pacman packages, systemd services, networking, data backup)
> 
> **Estimated Effort**: Large
> **Parallel Execution**: YES — 6 waves
> **Critical Path**: Compatibility layer design → Pilot modules → Batch refactoring → Station config → Evaluation

---

## Context

### Original Request
User wants to migrate "station" (AMD CPU + NVIDIA GPU desktop, dual 4K monitors, always-on build server) from NixOS to Arch Linux. Motivation: gaming/GPU drivers, proprietary software, AUR access, general NixOS desktop friction. Must keep the same Hyprland desktop environment and ability to deploy NixOS servers via colmena.

### Interview Summary
**Key Discussions**:
- **Hyprland**: Install via pacman, config managed by home-manager (not Nix-installed)
- **Theming**: Try `homeModules.stylix` for standalone HM. Same Nord theme.
- **System services**: ALL in scope — Docker, Ollama, PostgreSQL, Tailscale, Netbird, Syncthing, Sunshine, QEMU/KVM, SSH
- **Build server**: Keep station as Nix distributed build server on Arch (nix-daemon + nix-serve)
- **Module sharing**: Shared modules with compatibility layer — same source works in both NixOS and standalone mode
- **Branch**: New git branch `station-arch-migration`

**Research Findings**:
- All 50+ HM modules use `config.home-manager.users.${config.user}` pattern — these are NixOS modules wrapping HM config, NOT standalone HM modules
- Zero `osConfig` usage (good — no NixOS-specific reads from HM side)
- Custom NixOS options (`config.hyprland.kanshi.profiles`, `config.tmux.sessions`, `config.git.userName`, `config.styling.*`) are read cross-module — must be replicated in standalone context
- Stylix `homeModules.stylix` (not deprecated `homeManagerModules.stylix`) supports standalone mode with full feature parity
- sops-nix `homeManagerModules.sops` works standalone — secrets decrypt to `/run/user/1000/secrets/` instead of `/run/secrets/`
- Station has dual monitors: HDMI-A-1 (3840x2160@60), DP-1 (1920x1080@120)
- Station-specific overrides: swaylock disabled, hypridle disabled, opacity 0.85, gaps 0, custom workspace layout
- Other hosts (laptop, VNPC-21) reference station as build cache at `http://station:5000`

### Metis Review
**Identified Gaps** (addressed):

| Gap | Resolution |
|-----|-----------|
| HM modules aren't portable as-is — they're NixOS modules | Plan includes compatibility layer design + pilot testing before batch refactoring |
| nixGL required for Nix-installed GUI apps on Arch | Plan designates GPU-dependent apps for pacman install; nixGL for remaining |
| SOPS paths change (`/run/secrets/` → `/run/user/1000/secrets/`) | Task 17 explicitly handles path migration |
| nix-serve signing key location unknown | Task 18 documents discovery + preservation |
| PostgreSQL, Docker, Ollama data needs backup before wipe | Task 22 is a comprehensive data backup checklist |
| SSH host keys change on reinstall | Backup checklist includes `/etc/ssh/ssh_host_*` |
| Syncthing device ID regeneration | Backup checklist includes `~/.config/syncthing/` keys |
| NVIDIA dkms kernel rebuild risk on Arch | Setup guide recommends `linux-lts` kernel |
| XDG portals, PAM, polkit, greetd session file needed | System services guide covers all |
| Hyprland version vs HM config compatibility | Station config sets `wayland.windowManager.hyprland.package = null` to use system Hyprland |
| Font paths, locale, PATH ordering on Arch | Setup guide includes environment variable config |

---

## Work Objectives

### Core Objective
Enable station to run on Arch Linux with Nix package manager and standalone home-manager, preserving the identical desktop environment and server management capabilities, without breaking any existing NixOS hosts.

### Concrete Deliverables
- `parts/home-manager-standalone.nix` — New flake part with `homeConfigurations` output
- `hosts/station-arch/home.nix` — Station standalone HM config
- Refactored `modules/home-manager/` — All modules work in both NixOS-integrated and standalone mode
- `docs/station-arch-setup.md` — Complete Arch system setup runbook
- `docs/station-arch-backup.md` — Data backup/migration checklist

### Definition of Done
- [ ] `nix eval .#homeConfigurations."none@station".activationPackage.drvPath` succeeds
- [ ] `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` succeeds (no regression)
- [ ] `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath` succeeds (no regression)
- [ ] `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` succeeds (preserved for rollback)
- [ ] `nix build .#homeConfigurations."none@station".activationPackage --dry-run` succeeds

### Must Have
- All 50+ home-manager modules work identically in both NixOS and standalone mode
- Standalone HM config enables same modules as current station NixOS config
- Nord theme via stylix in standalone mode
- SOPS secrets in standalone mode
- Arch setup guide covers ALL current system services
- Zero impact on existing NixOS hosts (laptop, vnpc-21) and servers
- `nixosConfigurations.station` preserved (not removed) for rollback reference

### Must NOT Have (Guardrails)
- **NO behavior changes** during module refactoring — output-identical only
- **NO module improvements/optimizations** while porting — separate PR after migration
- **NO theme/keybind/desktop changes** — pixel-identical to current NixOS setup
- **NO Hyprland installed via Nix** on Arch — pacman only for WM
- **NO system config management tooling** for Arch — markdown docs, not scripts/ansible
- **NO changes to server configs** (pulse, sugar, byob, psychosocial, spiders)
- **NO changes to laptop or VNPC-21** configs (except build cache URL if IP changes)
- **NO module directory restructuring** — same paths, same names, only internal changes
- **NO removal of `nixosConfigurations.station`** — keep as documentation/rollback
- **NO merging/splitting/consolidating** modules during migration
- **NO new packages or capabilities** not in current station config

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES — `nix eval` and `nix build --dry-run` as primary TDD
- **Automated tests**: TDD-style — every module change verified with `nix eval` before and after
- **Framework**: Nix evaluation (`nix eval .#homeConfigurations...`, `nix eval .#nixosConfigurations...`)

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Nix config changes**: Use Bash (`nix eval`, `nix build --dry-run`) — Evaluate flake outputs, verify derivation paths
- **Module refactoring**: Use Bash (`nix eval`) — Verify BOTH NixOS and standalone evaluations succeed; compare derivation paths before/after
- **Documentation**: Use Bash (`grep`, file existence checks) — Verify required sections present

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — 5 parallel tasks):
├── Task 1: Create git branch [quick]
├── Task 2: Create parts/home-manager-standalone.nix [deep]
├── Task 3: Create hosts/station-arch/home.nix skeleton [quick]
├── Task 4: Validate stylix homeModules.stylix standalone [deep]
└── Task 5: Validate sops-nix homeManagerModules.sops standalone [deep]

Wave 2 (Compatibility Layer — 3 tasks, partially sequential):
├── Task 6: Design + implement HM module compatibility approach [ultrabrain]
├── Task 7: Pilot 3 representative modules (depends: 6) [deep]
└── Task 8: Regression test all NixOS hosts (depends: 7) [quick]

Wave 3 (Batch Module Refactoring — 6 parallel tasks):
├── Task 9: Refactor remaining cli/ modules (depends: 7, 8) [unspecified-high]
├── Task 10: Refactor neovim/ submodules (depends: 7, 8) [unspecified-high]
├── Task 11: Refactor app/ modules (depends: 7, 8) [unspecified-high]
├── Task 12: Refactor remaining desktop/hyprland/ modules (depends: 7, 8) [unspecified-high]
├── Task 13: Refactor misc/ modules (depends: 7, 8) [unspecified-high]
└── Task 14: Update module index files for standalone compat (depends: 7, 8) [unspecified-high]

Wave 4 (Station Config — 5 parallel tasks):
├── Task 15: Full station-arch home.nix config (depends: 9-14) [deep]
├── Task 16: Stylix standalone theming config (depends: 4, 14) [unspecified-high]
├── Task 17: SOPS standalone secrets config (depends: 5, 14) [unspecified-high]
├── Task 18: Nix daemon + build server config (depends: 14) [deep]
└── Task 19: Full evaluation test (depends: 15-18) [quick]

Wave 5 (Documentation — 3 parallel tasks, can overlap with Wave 4):
├── Task 20: Arch base system setup guide (depends: none) [writing]
├── Task 21: System services + pacman ownership guide (depends: none) [writing]
└── Task 22: Data backup/migration checklist (depends: none) [writing]

Wave FINAL (After ALL tasks — 4 parallel reviews):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real QA — full nix eval suite (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 2 → Task 6 → Task 7 → Task 8 → Tasks 9-14 → Task 15 → Task 19 → F1-F4 → user okay
Parallel Speedup: ~65% faster than sequential
Max Concurrent: 6 (Waves 1, 3, 5)
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1 | — | 2-22 (branch exists) | 1 |
| 2 | — | 6, 15 | 1 |
| 3 | — | 15 | 1 |
| 4 | — | 16 | 1 |
| 5 | — | 17 | 1 |
| 6 | 2 | 7 | 2 |
| 7 | 6 | 8, 9-14 | 2 |
| 8 | 7 | 9-14 | 2 |
| 9 | 7, 8 | 15, 19 | 3 |
| 10 | 7, 8 | 15, 19 | 3 |
| 11 | 7, 8 | 15, 19 | 3 |
| 12 | 7, 8 | 15, 19 | 3 |
| 13 | 7, 8 | 15, 19 | 3 |
| 14 | 7, 8 | 15-18 | 3 |
| 15 | 9-14, 2, 3 | 19 | 4 |
| 16 | 4, 14 | 19 | 4 |
| 17 | 5, 14 | 19 | 4 |
| 18 | 14 | 19 | 4 |
| 19 | 15-18 | F1-F4 | 4 |
| 20 | — | F1 | 5 |
| 21 | — | F1 | 5 |
| 22 | — | F1 | 5 |

### Agent Dispatch Summary

- **Wave 1**: **5** — T1 → `quick`, T2 → `deep`, T3 → `quick`, T4 → `deep`, T5 → `deep`
- **Wave 2**: **3** — T6 → `ultrabrain`, T7 → `deep`, T8 → `quick`
- **Wave 3**: **6** — T9-T14 → `unspecified-high`
- **Wave 4**: **5** — T15 → `deep`, T16-T17 → `unspecified-high`, T18 → `deep`, T19 → `quick`
- **Wave 5**: **3** — T20-T22 → `writing`
- **FINAL**: **4** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Create git branch `station-arch-migration`

  **What to do**:
  - Create and switch to a new branch `station-arch-migration` from the current HEAD
  - Verify the branch was created successfully

  **Must NOT do**:
  - Push to remote (user will push when ready)
  - Make any file changes in this task

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`git-master`]
    - `git-master`: Git branch operations

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4, 5)
  - **Blocks**: All subsequent tasks (branch must exist)
  - **Blocked By**: None

  **References**:
  - **Pattern References**: None needed — simple git operation
  - **External References**: None

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Branch created successfully
    Tool: Bash
    Preconditions: On main branch with clean working tree
    Steps:
      1. Run `git checkout -b station-arch-migration`
      2. Run `git branch --show-current`
    Expected Result: Output is "station-arch-migration"
    Failure Indicators: Branch already exists, or current branch is not station-arch-migration
    Evidence: .sisyphus/evidence/task-1-branch-created.txt
  ```

  **Commit**: NO (no file changes)

---

- [x] 2. Create `parts/home-manager-standalone.nix` with `homeConfigurations` output

  **What to do**:
  - Create `parts/home-manager-standalone.nix` that defines a `homeConfigurations` flake output
  - Register it as an import in `flake.nix`
  - Define `homeConfigurations."none@station"` using `inputs.home-manager.lib.homeManagerConfiguration`
  - Pass `pkgs` from nixpkgs with `config.allowUnfree = true`
  - Pass `extraSpecialArgs` with inputs and any shared variables (like username)
  - Import a minimal `hosts/station-arch/home.nix` (created in Task 3)
  - The `homeConfigurations` output should be separate from `nixosConfigurations` — no coupling
  - Ensure `system = "x86_64-linux"`

  **Must NOT do**:
  - Touch existing `parts/hosts.nix` or `parts/deploy.nix`
  - Remove or modify `nixosConfigurations.station`
  - Import NixOS-specific modules (no `modules/nixos/`)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `server-add-service`: Server-specific, not relevant to flake restructuring

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4, 5)
  - **Blocks**: Task 6 (compatibility layer needs the output registered), Task 15 (station config)
  - **Blocked By**: None (Task 1 branch creation is a soft dependency — can be same wave)

  **References**:

  **Pattern References**:
  - `parts/hosts.nix` — How `nixosConfigurations` are defined; model the `homeConfigurations` output similarly but using `home-manager.lib.homeManagerConfiguration`
  - `parts/lib.nix` — The `hostModules` and `commonModules` functions; understand what gets passed to desktop hosts so standalone can replicate relevant parts
  - `flake.nix` — Import list in `imports = [...]`; add the new file here

  **API/Type References**:
  - `inputs.home-manager` — The home-manager flake input; use `inputs.home-manager.lib.homeManagerConfiguration`
  - `inputs.nixpkgs` — For `import inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }`

  **External References**:
  - Home Manager standalone docs: https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone

  **WHY Each Reference Matters**:
  - `parts/hosts.nix` — Shows the flake-parts pattern for defining system configs; replicate this pattern for home configs
  - `parts/lib.nix` — Contains `commonModules` list; some of these (like home-manager module) are NixOS-specific and must NOT be imported in standalone mode
  - `flake.nix` — Must add `./parts/home-manager-standalone.nix` to the imports list

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: homeConfigurations output exists in flake
    Tool: Bash
    Preconditions: parts/home-manager-standalone.nix created, flake.nix updated
    Steps:
      1. Run `nix flake show --json 2>/dev/null | jq '.homeConfigurations'`
      2. Verify "none@station" key exists
    Expected Result: JSON object containing "none@station" key
    Failure Indicators: null output, evaluation error, missing key
    Evidence: .sisyphus/evidence/task-2-flake-show.txt

  Scenario: Standalone HM evaluates without error
    Tool: Bash
    Preconditions: Minimal home.nix exists (from Task 3)
    Steps:
      1. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: A nix store path string (no errors)
    Failure Indicators: Evaluation error, missing module, infinite recursion
    Evidence: .sisyphus/evidence/task-2-hm-eval.txt

  Scenario: Existing NixOS hosts unaffected
    Tool: Bash
    Preconditions: flake.nix modified to import new file
    Steps:
      1. Run `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath 2>&1`
      2. Run `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath 2>&1`
      3. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
    Expected Result: All three return valid nix store paths
    Failure Indicators: Evaluation error in any host
    Evidence: .sisyphus/evidence/task-2-nixos-regression.txt
  ```

  **Commit**: YES
  - Message: `feat(flake): add homeConfigurations output for standalone home-manager`
  - Files: `parts/home-manager-standalone.nix`, `flake.nix`
  - Pre-commit: `nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [x] 3. Create `hosts/station-arch/home.nix` skeleton

  **What to do**:
  - Create directory `hosts/station-arch/`
  - Create `hosts/station-arch/home.nix` with minimal standalone home-manager config:
    - `home.username = "none"`
    - `home.homeDirectory = "/home/none"`
    - `home.stateVersion = "25.05"`
    - `programs.home-manager.enable = true`
  - This is a SKELETON — full module enables come in Task 15 after module refactoring

  **Must NOT do**:
  - Enable any modules yet (they haven't been refactored for standalone)
  - Copy content from `hosts/station/default.nix` — that's NixOS config

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4, 5)
  - **Blocks**: Task 15 (full station config builds on this)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `hosts/station/default.nix` — Reference for station-specific values (username, hostname, monitors) but do NOT copy NixOS options
  - `hosts/laptop/default.nix` — Another desktop host for comparison of the config pattern

  **WHY Each Reference Matters**:
  - `hosts/station/default.nix` — Source of truth for station's username (`none`), monitor config, and overrides that need to be ported in Task 15

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Skeleton home.nix evaluates
    Tool: Bash
    Preconditions: hosts/station-arch/home.nix created, Task 2 complete
    Steps:
      1. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Valid nix store path (no errors)
    Failure Indicators: Evaluation error, missing attribute
    Evidence: .sisyphus/evidence/task-3-skeleton-eval.txt
  ```

  **Commit**: YES (groups with Task 2)
  - Message: `feat(flake): add homeConfigurations output for standalone home-manager`
  - Files: `hosts/station-arch/home.nix`

---

- [x] 4. Validate stylix `homeModules.stylix` works in standalone HM

  **What to do**:
  - Research how `inputs.stylix.homeModules.stylix` works in standalone home-manager context
  - Test by temporarily adding stylix to the minimal station-arch config:
    - Import `inputs.stylix.homeModules.stylix`
    - Set `stylix.enable = true` with a base16 scheme and image
    - Run `nix eval` to verify it evaluates
  - Document findings: what options work, what doesn't, any caveats
  - **IMPORTANT**: Use `homeModules.stylix` NOT deprecated `homeManagerModules.stylix`
  - Revert the temporary test after validation (don't leave half-configured stylix in skeleton)

  **Must NOT do**:
  - Permanently modify the skeleton config (this is research)
  - Change existing NixOS stylix configuration
  - Design the final theming config (that's Task 16)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 5)
  - **Blocks**: Task 16 (stylix standalone config depends on validation results)
  - **Blocked By**: Tasks 2, 3 (needs evaluable homeConfigurations)

  **References**:

  **Pattern References**:
  - `modules/nixos/styling.nix` — Current NixOS stylix config; understand what options are set (base16Scheme, image, cursor, fonts, opacity, polarity) to know what must work standalone
  - `profiles/base.nix:styling.*` — Default styling options (theme=nord, polarity=dark, opacity=0.90, cursor.size=20)

  **External References**:
  - Stylix GitHub: https://github.com/danth/stylix — Check README for standalone HM usage
  - Stylix docs on home-manager: https://danth.github.io/stylix/

  **WHY Each Reference Matters**:
  - `modules/nixos/styling.nix` — Lists ALL stylix options currently used; standalone must support the same ones
  - Stylix GitHub — Authoritative source for `homeModules.stylix` API

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Stylix evaluates in standalone HM
    Tool: Bash
    Preconditions: homeConfigurations exists with stylix imported
    Steps:
      1. Temporarily add `inputs.stylix.homeModules.stylix` to station-arch imports
      2. Set `stylix.enable = true; stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml"; stylix.image = ./wallpaper.png;`
      3. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
      4. Revert temporary changes
    Expected Result: Evaluation succeeds (no errors about missing NixOS options)
    Failure Indicators: "option stylix.* does not exist", infinite recursion, NixOS-only dependency
    Evidence: .sisyphus/evidence/task-4-stylix-standalone.txt

  Scenario: Stylix fails gracefully if incompatible
    Tool: Bash
    Preconditions: Same as above
    Steps:
      1. If evaluation fails, capture the exact error message
      2. Document which specific options are NixOS-only
      3. Identify fallback approach (nix-colors, manual GTK/Qt config)
    Expected Result: Clear documentation of what works and what doesn't
    Failure Indicators: Unclear error, no actionable information
    Evidence: .sisyphus/evidence/task-4-stylix-fallback.txt
  ```

  **Commit**: NO (research task — findings inform Task 16)

---

- [x] 5. Validate sops-nix `homeManagerModules.sops` works in standalone HM

  **What to do**:
  - Research how `inputs.sops-nix.homeManagerModules.sops` works in standalone context
  - Test by temporarily adding sops to minimal station-arch config:
    - Import `inputs.sops-nix.homeManagerModules.sops`
    - Set `sops.age.keyFile` to the existing key path
    - Define a test secret
    - Run `nix eval` to verify it evaluates
  - Document: where secrets decrypt to (expected: `/run/user/1000/secrets/`), key file handling, any caveats
  - Verify that `inputs.sops-nix` is already in the flake inputs
  - Revert temporary test after validation

  **Must NOT do**:
  - Permanently modify the skeleton config
  - Change existing NixOS SOPS configuration
  - Design final secrets config (that's Task 17)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 4)
  - **Blocks**: Task 17 (SOPS standalone config depends on validation results)
  - **Blocked By**: Tasks 2, 3 (needs evaluable homeConfigurations)

  **References**:

  **Pattern References**:
  - `modules/nixos/secrets.nix` — Current NixOS SOPS config; understand key file paths and secret definitions
  - `hosts/station/default.nix` — Station's specific SOPS config: `sops.defaultSopsFile`, `sops.age.keyFile`
  - `secrets/secrets.yaml` — Shared secrets file (do NOT read contents — encrypted). Note: `hosts/station/default.nix` references `secrets/general.yaml` which does NOT exist in the repo — the actual shared secrets file is `secrets/secrets.yaml` (set in `modules/nixos/secrets.nix`). This is a pre-existing discrepancy.
  - `secrets/station.yaml` — Station-specific secrets (do NOT read contents)
  - `modules/home-manager/cli/mcp.nix` — Reads `GITHUB_PERSONAL_ACCESS_TOKEN` from `/run/secrets/github_token`; path must change

  **External References**:
  - sops-nix GitHub: https://github.com/Mic92/sops-nix — Check for home-manager standalone usage

  **WHY Each Reference Matters**:
  - `modules/nixos/secrets.nix` — Shows current secret definitions that must be replicated
  - `modules/home-manager/cli/mcp.nix` — The MCP module hardcodes `/run/secrets/` path which will break with standalone SOPS (`/run/user/1000/secrets/`)

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: SOPS evaluates in standalone HM
    Tool: Bash
    Preconditions: homeConfigurations exists with sops imported
    Steps:
      1. Temporarily add `inputs.sops-nix.homeManagerModules.sops` to imports
      2. Set `sops.age.keyFile = "/home/none/.config/sops/age/keys.txt"`
      3. Define a test secret: `sops.secrets.test = { sopsFile = ../../secrets/secrets.yaml; }`
      4. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
      5. Revert temporary changes
    Expected Result: Evaluation succeeds
    Failure Indicators: Missing module, key file error, sops integration error
    Evidence: .sisyphus/evidence/task-5-sops-standalone.txt

  Scenario: Document secret path differences
    Tool: Bash
    Preconditions: SOPS evaluation succeeds
    Steps:
      1. Check sops-nix source/docs for standalone secret output path
      2. Document: NixOS path `/run/secrets/*` vs standalone path `/run/user/1000/secrets/*`
      3. Grep for all `/run/secrets/` references in home-manager modules
    Expected Result: List of all modules that reference `/run/secrets/` and need path updates
    Failure Indicators: Missed references
    Evidence: .sisyphus/evidence/task-5-sops-paths.txt
  ```

  **Commit**: NO (research task — findings inform Task 17)

---

- [x] 6. Design + implement HM module compatibility approach

  **What to do**:
  This is the **most critical task** in the entire migration. The ~50 home-manager modules currently use this NixOS-integrated pattern:
  ```nix
  { config, lib, pkgs, ... }:
  {
    options.moduleName.enable = lib.mkEnableOption "...";
    config.home-manager.users.${config.user} = lib.mkIf config.moduleName.enable {
      # actual home-manager config here
    };
  }
  ```
  
  For standalone home-manager, there is no `config.home-manager.users` — config IS the user's config directly. Additionally, modules read cross-module NixOS options like `config.user`, `config.styling.*`, `config.hyprland.*`.

  **Design TWO approaches, implement the better one:**

  **Approach A — Compatibility Shim**:
  Create a module that provides `config.home-manager.users.${config.user}` as an alias that maps to direct HM config in standalone mode. Also provide `config.user` and other cross-module options.
  - Pros: No changes to existing modules
  - Cons: Complex, potentially fragile

  **Approach B — Two-Layer Extraction**:
  Extract the inner HM config from each module into a pure function/module. NixOS wrapper calls it via `config.home-manager.users.*`. Standalone imports it directly.
  - Pros: Clean architecture, clear separation
  - Cons: Touches every module file

  **Steps**:
  1. Analyze ALL cross-module option reads (grep for `config.user`, `config.styling`, `config.hyprland`, `config.tmux`, `config.git`) to understand full dependency graph
  2. Prototype BOTH approaches with a single simple module
  3. Evaluate: which is simpler, less fragile, easier to maintain?
  4. Implement the chosen approach as a shared compatibility module/library
  5. Document the architecture decision with rationale in a code comment

  **Must NOT do**:
  - Touch any actual module files yet (that's the pilot in Task 7)
  - Change module behavior — this is pure infrastructure
  - Over-engineer — pick the simpler approach that works

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
  - **Skills**: []
    - Reason: Nix module system architecture requires deep understanding of the evaluation model, option types, and module composition. This is the hardest task in the plan.

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sequential)
  - **Blocks**: Task 7 (pilot needs the approach implemented)
  - **Blocked By**: Task 2 (needs homeConfigurations output to test against)

  **References**:

  **Pattern References**:
  - `modules/home-manager/default.nix` — Top-level HM module that defines `config.user` option; this is the NixOS-side user option that ALL modules reference
  - `modules/home-manager/cli/git.nix` — Simple module example; representative of the `config.home-manager.users.${config.user}` pattern
  - `modules/home-manager/desktop/hyprland/default.nix` — Complex module with cross-module option reads (`config.hyprland.kanshi.profiles`, etc.)
  - `modules/home-manager/cli/mcp.nix` — Module that reads SOPS secrets paths
  - `parts/lib.nix` — How modules are currently composed via `hostModules` and `commonModules`; understand the import chain

  **API/Type References**:
  - `lib.mkOption`, `lib.mkEnableOption`, `lib.mkIf` — Nix module system primitives
  - `config.home-manager.users.${config.user}` — The NixOS-HM bridge pattern that must be shimmed or replaced

  **External References**:
  - Nix module system docs: https://nixos.org/manual/nixos/stable/#sec-writing-modules
  - Home Manager module system: https://nix-community.github.io/home-manager/index.xhtml#ch-writing-modules

  **WHY Each Reference Matters**:
  - `modules/home-manager/default.nix` — Defines `options.user` which every module reads as `config.user`; must be replicated or replaced in standalone context
  - `modules/home-manager/cli/git.nix` — Simplest example of the pattern; good first target for prototyping
  - `modules/home-manager/desktop/hyprland/default.nix` — Most complex example with multiple cross-module reads; tests the approach's limits

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Cross-module option dependency map is complete
    Tool: Bash
    Preconditions: Repository cloned
    Steps:
      1. Run `grep -r 'config\.user' modules/home-manager/ --include='*.nix' -l` to find all user references
      2. Run `grep -r 'config\.\(styling\|hyprland\|tmux\|git\)' modules/home-manager/ --include='*.nix' -l` to find cross-module reads
      3. Document every cross-module dependency
    Expected Result: Complete list of cross-module option reads across all HM modules
    Failure Indicators: Missed dependencies (would cause eval failures in later tasks)
    Evidence: .sisyphus/evidence/task-6-dependency-map.txt

  Scenario: Chosen compatibility approach evaluates
    Tool: Bash
    Preconditions: Compatibility module/shim implemented
    Steps:
      1. Create a test configuration that imports the compatibility layer + one simple module
      2. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
      3. Verify no evaluation errors
    Expected Result: Successful evaluation with the compatibility layer active
    Failure Indicators: Infinite recursion, missing option, type mismatch
    Evidence: .sisyphus/evidence/task-6-compat-eval.txt

  Scenario: Architecture decision documented
    Tool: Bash
    Preconditions: Approach chosen and implemented
    Steps:
      1. Read the compatibility module/shim file
      2. Verify it contains a comment block explaining: approach chosen, alternatives considered, rationale
    Expected Result: Clear architectural documentation in code
    Failure Indicators: No rationale, unclear explanation
    Evidence: .sisyphus/evidence/task-6-architecture-doc.txt
  ```

  **Commit**: YES
  - Message: `refactor(hm): add standalone compatibility layer for HM modules`
  - Files: New compatibility module/shim file(s)
  - Pre-commit: `nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [x] 7. Pilot: Refactor 3 representative modules + validate both modes

  **What to do**:
  Apply the compatibility approach from Task 6 to exactly 3 pilot modules, chosen to cover different complexity levels:

  1. **`modules/home-manager/cli/git.nix`** — Simple CLI module. Minimal cross-module reads (only `config.user`). Tests basic pattern.
  2. **`modules/home-manager/desktop/hyprland/default.nix`** — Complex desktop module. Multiple cross-module option reads (`config.hyprland.kanshi.profiles`, etc.). Tests the approach's limits.
  3. **`modules/home-manager/cli/mcp.nix`** — Secrets-dependent module. Reads from `/run/secrets/github_token`. Tests SOPS path handling.

  For EACH pilot module:
  1. Record the derivation path BEFORE refactoring: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath`
  2. Apply the compatibility approach
  3. Verify NixOS evaluation still works: derivation path UNCHANGED
  4. Verify standalone evaluation works: `nix eval .#homeConfigurations."none@station".activationPackage.drvPath`
  5. If any pilot fails, STOP and revisit the compatibility approach in Task 6

  **Must NOT do**:
  - Change module behavior — derivation paths must be identical before/after
  - Refactor modules beyond the 3 pilots (that's Wave 3)
  - Skip the derivation path comparison — this is the core safety check

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (sequential — each pilot informs the next)
  - **Parallel Group**: Wave 2 (sequential after Task 6)
  - **Blocks**: Task 8, Tasks 9-14
  - **Blocked By**: Task 6 (needs compatibility approach)

  **References**:

  **Pattern References**:
  - `modules/home-manager/cli/git.nix` — Pilot module 1 (simple)
  - `modules/home-manager/desktop/hyprland/default.nix` — Pilot module 2 (complex)
  - `modules/home-manager/cli/mcp.nix` — Pilot module 3 (secrets)
  - The compatibility module from Task 6 — The approach being validated

  **WHY Each Reference Matters**:
  - Each pilot module tests a different aspect: basic pattern (git), cross-module reads (hyprland), external path dependencies (mcp)
  - The compatibility module is the implementation being tested against real modules

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: NixOS derivation path unchanged for each pilot
    Tool: Bash
    Preconditions: Compatibility layer from Task 6 in place
    Steps:
      1. Record BEFORE path: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1 > /tmp/before.txt`
      2. Apply refactoring to pilot module
      3. Record AFTER path: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1 > /tmp/after.txt`
      4. Run `diff /tmp/before.txt /tmp/after.txt`
    Expected Result: No differences (identical derivation paths)
    Failure Indicators: Different derivation paths = behavior change
    Evidence: .sisyphus/evidence/task-7-pilot-{name}-nixos-drv.txt

  Scenario: Standalone evaluation succeeds for each pilot
    Tool: Bash
    Preconditions: Pilot module refactored, enabled in station-arch config
    Steps:
      1. Enable the pilot module in hosts/station-arch/home.nix
      2. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Successful evaluation (no errors)
    Failure Indicators: Evaluation error, missing option, infinite recursion
    Evidence: .sisyphus/evidence/task-7-pilot-{name}-standalone-eval.txt

  Scenario: All NixOS hosts still evaluate after all pilots
    Tool: Bash
    Preconditions: All 3 pilot modules refactored
    Steps:
      1. Run `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath 2>&1`
      2. Run `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath 2>&1`
      3. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      4. Run `nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath 2>&1`
      5. Run `nix eval .#nixosConfigurations.installer.config.system.build.toplevel.drvPath 2>&1`
    Expected Result: All 5 succeed (spot-check — full 9-host regression in Task 8)
    Failure Indicators: Any evaluation failure
    Evidence: .sisyphus/evidence/task-7-regression-all-hosts.txt
  ```

  **Commit**: YES
  - Message: `refactor(hm): pilot standalone compat — git, hyprland, mcp modules`
  - Files: `modules/home-manager/cli/git.nix`, `modules/home-manager/desktop/hyprland/default.nix`, `modules/home-manager/cli/mcp.nix`, `hosts/station-arch/home.nix`
  - Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [x] 8. Regression test: all NixOS hosts evaluate correctly

  **What to do**:
  - Run comprehensive evaluation tests for ALL NixOS configurations after the pilot refactoring
  - Test every `nixosConfigurations` entry — not just station, laptop, vnpc-21 but ALL including servers
  - This is the green light gate for batch refactoring in Wave 3

  **Must NOT do**:
  - Make any code changes — this is pure verification
  - Skip any host — test them all

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (must run after Task 7)
  - **Parallel Group**: Wave 2 (after Task 7)
  - **Blocks**: Tasks 9-14 (batch refactoring only proceeds if this passes)
  - **Blocked By**: Task 7

  **References**:

  **Pattern References**:
  - `parts/hosts.nix` — Lists ALL nixosConfigurations; iterate through each one
  - `parts/deploy.nix` — Lists all colmena hosts; verify these match

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Every nixosConfiguration evaluates successfully
    Tool: Bash
    Preconditions: Tasks 6-7 complete
    Steps:
      1. Run `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath 2>&1`
      2. Run `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath 2>&1`
      3. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      4. Run `nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath 2>&1`
      5. Run `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath 2>&1`
      6. Run `nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath 2>&1`
      7. Run `nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath 2>&1`
      8. Run `nix eval .#nixosConfigurations.spiders.config.system.build.toplevel.drvPath 2>&1`
      9. Run `nix eval .#nixosConfigurations.installer.config.system.build.toplevel.drvPath 2>&1`
    Expected Result: ALL evaluations succeed (9/9 pass)
    Failure Indicators: ANY evaluation failure = regression introduced
    Evidence: .sisyphus/evidence/task-8-full-regression.txt
  ```

  **Commit**: NO (verification only)

- [ ] 9. Refactor remaining `cli/` modules for standalone compatibility

  **What to do**:
  Apply the SAME compatibility approach validated in Task 7 to ALL remaining CLI modules (excluding `git.nix` and `mcp.nix` — already done in pilot):
  - `cli/zsh/default.nix`, `cli/zsh/zsh.nix`, `cli/zsh/aliases.nix`, `cli/zsh/eza.nix`
  - `cli/tmux.nix`
  - `cli/kitty.nix`
  - `cli/ghostty.nix`
  - `cli/zellij.nix`
  - `cli/direnv.nix`
  - `cli/kubernetes.nix`
  - `cli/languages.nix`
  - `cli/system-tools.nix`
  - `cli/xdg.nix`
  - `cli/prompt.nix`

  For EACH module: apply the compatibility refactoring, verify NixOS eval unchanged.
  After ALL cli/ modules done: run full NixOS + standalone eval.

  **Must NOT do**:
  - Change any module behavior — output-identical refactoring only
  - Improve, optimize, or consolidate modules while porting
  - Touch `cli/git.nix` or `cli/mcp.nix` (already done in Task 7)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 10, 11, 12, 13, 14)
  - **Blocks**: Task 15 (station config needs modules working)
  - **Blocked By**: Tasks 7, 8 (pilot must pass, regression must pass)

  **References**:

  **Pattern References**:
  - The pilot module refactoring from Task 7 (`cli/git.nix`) — Follow this EXACT pattern for all cli/ modules
  - `modules/home-manager/cli/tmux.nix` — Has custom `config.tmux.sessions` option; check for cross-module reads
  - `modules/home-manager/cli/zsh/default.nix` — Multi-file module (default.nix + submodules); ensure import chain works

  **WHY Each Reference Matters**:
  - Task 7 pilot pattern — The validated approach; copy it exactly
  - `tmux.nix` — One of the more complex CLI modules with custom options that other modules may read
  - `zsh/default.nix` — Tests multi-file module compatibility

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: All cli/ modules evaluate in NixOS mode
    Tool: Bash
    Preconditions: All cli/ modules refactored
    Steps:
      1. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
    Expected Result: Successful evaluation
    Failure Indicators: Any evaluation error
    Evidence: .sisyphus/evidence/task-9-cli-nixos-eval.txt

  Scenario: All cli/ modules evaluate in standalone mode
    Tool: Bash
    Preconditions: All cli/ modules refactored, enabled in station-arch home.nix
    Steps:
      1. Enable all cli modules in station-arch home.nix
      2. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Successful evaluation
    Failure Indicators: Missing option, wrong attribute path, evaluation error
    Evidence: .sisyphus/evidence/task-9-cli-standalone-eval.txt
  ```

  **Commit**: YES
  - Message: `refactor(hm): migrate cli modules to dual-mode compatibility`
  - Files: All `modules/home-manager/cli/*.nix` files (except git.nix, mcp.nix)
  - Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [ ] 10. Refactor `neovim/` submodules for standalone compatibility

  **What to do**:
  Apply compatibility approach to ALL neovim submodules:
  - `cli/neovim/default.nix` (main entry)
  - `cli/neovim/nixvim.nix`, `lsp.nix`, `cmp.nix`, `harpoon.nix`, `telescope.nix`
  - `cli/neovim/nvim-tree.nix`, `conform.nix`, `lint.nix`, `mini.nix`
  - `cli/neovim/obsidian.nix`, `auto-save.nix`, `render-markdown.nix`, `maps.nix`, `options.nix`

  These are likely all imported through `neovim/default.nix`. Check whether submodules use the `config.home-manager.users` pattern individually or are nested under the parent.

  **Must NOT do**:
  - Change neovim configuration, plugins, or keybindings
  - Add/remove any nixvim plugins

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 11, 12, 13, 14)
  - **Blocks**: Task 15
  - **Blocked By**: Tasks 7, 8

  **References**:

  **Pattern References**:
  - Task 7 pilot pattern — Follow the validated approach
  - `modules/home-manager/cli/neovim/default.nix` — Entry point that imports all submodules; understand the import chain
  - `modules/home-manager/cli/neovim/lsp.nix` — Example submodule to check pattern

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Neovim module evaluates in both modes
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      2. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Both succeed
    Evidence: .sisyphus/evidence/task-10-neovim-dual-eval.txt
  ```

  **Commit**: YES
  - Message: `refactor(hm): migrate neovim submodules to dual-mode compatibility`
  - Files: All `modules/home-manager/cli/neovim/*.nix`
  - Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [ ] 11. Refactor `app/` modules for standalone compatibility

  **What to do**:
  Apply compatibility approach to ALL app modules:
  - `app/default.nix`
  - `app/discord.nix`
  - `app/development.nix`
  - `app/media.nix`
  - `app/communication.nix`
  - `app/utilities.nix`
  - `app/lmstudio.nix`

  **Must NOT do**:
  - Change application lists or settings
  - Add/remove any packages

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 12, 13, 14)
  - **Blocks**: Task 15
  - **Blocked By**: Tasks 7, 8

  **References**:

  **Pattern References**:
  - Task 7 pilot pattern — Follow the validated approach
  - `modules/home-manager/app/discord.nix` — Example app module; check if they follow same `config.home-manager.users` pattern

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: App modules evaluate in both modes
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      2. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Both succeed
    Evidence: .sisyphus/evidence/task-11-app-dual-eval.txt
  ```

  **Commit**: YES
  - Message: `refactor(hm): migrate app modules to dual-mode compatibility`
  - Files: All `modules/home-manager/app/*.nix`
  - Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [ ] 12. Refactor remaining `desktop/hyprland/` modules for standalone compatibility

  **What to do**:
  Apply compatibility approach to remaining Hyprland modules (excluding `default.nix` — done in Task 7 pilot):
  - `desktop/hyprland/packages.nix`
  - `desktop/hyprland/services.nix`
  - `desktop/hyprland/hyprpanel.nix`
  - `desktop/hyprland/keybindings.nix`
  - `desktop/hyprland/monitors.nix`

  **Special attention**: These modules may read cross-module options like `config.hyprland.*`. The compatibility layer from Task 6 must provide these options in standalone mode.

  **Must NOT do**:
  - Change keybindings, monitor configs, or Hyprland settings
  - Modify the Hyprland configuration behavior

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 11, 13, 14)
  - **Blocks**: Task 15
  - **Blocked By**: Tasks 7, 8

  **References**:

  **Pattern References**:
  - Task 7 pilot for `desktop/hyprland/default.nix` — The validated approach for complex Hyprland modules
  - `modules/home-manager/desktop/hyprland/monitors.nix` — Reads monitor config options; needs station-specific dual-monitor setup
  - `modules/home-manager/desktop/hyprland/keybindings.nix` — Custom keybinds; verify no NixOS-only dependencies
  - `modules/home-manager/desktop/hyprland/services.nix` — Swaylock, Hypridle (disabled on station); verify disable mechanism works in standalone

  **WHY Each Reference Matters**:
  - `monitors.nix` — Station has custom dual-monitor config (HDMI-A-1 + DP-1); must work identically in standalone
  - `services.nix` — Station disables swaylock and hypridle; the disable mechanism must work via the compatibility layer

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Hyprland modules evaluate in both modes
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      2. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Both succeed
    Evidence: .sisyphus/evidence/task-12-hyprland-dual-eval.txt
  ```

  **Commit**: YES
  - Message: `refactor(hm): migrate desktop + hyprland modules to dual-mode compatibility`
  - Files: All `modules/home-manager/desktop/hyprland/*.nix` (except default.nix — Task 7)
  - Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [ ] 13. Refactor `misc/` modules for standalone compatibility

  **What to do**:
  Apply compatibility approach to:
  - `misc/default.nix`
  - `misc/chromium.nix`
  - `misc/zen-browser.nix`
  - `misc/thunar.nix`

  **Note on browsers**: Chromium and Zen Browser on Arch may need nixGL wrapping if installed via Nix (GPU acceleration). Document this in the module comments for Task 15.

  **Must NOT do**:
  - Change browser extensions, settings, or flags
  - Add nixGL wrapping (that's an Arch-specific concern for Task 15/21)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 11, 12, 14)
  - **Blocks**: Task 15
  - **Blocked By**: Tasks 7, 8

  **References**:

  **Pattern References**:
  - Task 7 pilot pattern
  - `modules/home-manager/misc/chromium.nix` — Browser with extensions; check for NixOS-specific flags
  - `modules/home-manager/misc/zen-browser.nix` — Has Wayland/NVIDIA environment variables

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Misc modules evaluate in both modes
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      2. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Both succeed
    Evidence: .sisyphus/evidence/task-13-misc-dual-eval.txt
  ```

  **Commit**: YES (groups with Task 12)
  - Message: `refactor(hm): migrate desktop + misc modules to dual-mode compatibility`
  - Files: All `modules/home-manager/misc/*.nix`

---

- [ ] 14. Update module index files (`default.nix`) for standalone compatibility

  **What to do**:
  Update the category-level and top-level `default.nix` files to work in both NixOS and standalone mode:
  - `modules/home-manager/default.nix` — Top-level; defines `options.user`; imports all categories
  - `modules/home-manager/cli/default.nix` — Imports all CLI modules
  - `modules/home-manager/app/default.nix` — Imports all app modules
  - `modules/home-manager/desktop/default.nix` — Imports all desktop modules
  - `modules/home-manager/misc/default.nix` — Imports all misc modules

  The top-level `default.nix` is CRITICAL — it defines `config.user` which ALL modules reference. In standalone mode, `config.user` must resolve to the username (passed via `extraSpecialArgs` or defined locally).

  **Must NOT do**:
  - Change the module import structure (same files imported)
  - Remove the `config.user` option (NixOS hosts still need it)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10, 11, 12, 13)
  - **Blocks**: Tasks 15-18 (all Wave 4 tasks need module system working)
  - **Blocked By**: Tasks 7, 8

  **References**:

  **Pattern References**:
  - `modules/home-manager/default.nix` — THE critical file; defines `options.user` and imports everything. Must work in both evaluation contexts.
  - The compatibility module from Task 6 — How `config.user` is provided in standalone mode

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Full module tree evaluates in both modes
    Tool: Bash
    Steps:
      1. Import all modules in station-arch home.nix via the top-level default.nix
      2. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      3. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: Both succeed with the full module tree
    Failure Indicators: Import errors, missing options, circular dependencies
    Evidence: .sisyphus/evidence/task-14-full-tree-eval.txt

  Scenario: Full regression test — all NixOS hosts
    Tool: Bash
    Steps:
      1. Evaluate ALL nixosConfigurations (laptop, VNPC-21, station, pulse, sugar, byob, psychosocial, spiders, installer)
    Expected Result: ALL 9 hosts evaluate successfully
    Evidence: .sisyphus/evidence/task-14-full-regression.txt
  ```

  **Commit**: YES
  - Message: `refactor(hm): update module index files for standalone support`
  - Files: All `modules/home-manager/**/default.nix` files
  - Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#homeConfigurations."none@station".activationPackage.drvPath`

---

- [ ] 15. Full station-arch `home.nix` with all module enables + overrides

  **What to do**:
  Build the complete `hosts/station-arch/home.nix` configuration that replicates station's current NixOS setup:

  **Home-Manager Module Enables** (ONLY modules defined in `modules/home-manager/`):
  These are the modules that belong in `home.nix` — they are HM modules managed by the compatibility layer:
  - **CLI**: neovim, zsh, prompt, kitty, ghostty, tmux, system-tools, git, direnv, languages, xdg, kubernetes, mcp
  - **Apps**: discord, development, media, communication, utilities, lmstudio
  - **Desktop**: hyprland (config only — Hyprland binary comes from pacman)
  - **Misc**: thunar, chromium, zen-browser

  **NixOS-Only Modules — NOT in home.nix** (these are system services, handled by Arch/pacman per Tasks 20-21):
  The following options from `profiles/base.nix` are defined in `modules/nixos/` and CANNOT be set in standalone HM:
  - `general.enable` → Arch pacman base packages (see Task 21)
  - `fonts.enable` → Arch font packages + fontconfig (see Task 20)
  - `audio.enable` → PipeWire via pacman (see Task 21)
  - `wireless.enable` → NetworkManager via pacman (see Task 21)
  - `bluetooth.enable` → bluez via pacman (see Task 21)
  - `_1password.enable` → 1Password from AUR (see Task 21)
  - `tailscale.enable` → tailscale via pacman (see Task 21)
  - `syncthing.enable` → syncthing via pacman (see Task 21)
  - `polkit.enable` → polkit via pacman (see Task 20)
  - `sunshine.enable` → sunshine from AUR (see Task 21)
  - `openssh.enable` → openssh via pacman (see Task 21)
  - `virtualization.enable` → QEMU/libvirt via pacman (see Task 21)
  - `gaming.enable` → Heroic/Bottles from AUR/Flatpak (see Task 21)
  - `ollama.enable` → ollama-cuda from AUR (see Task 21)
  - `protonvpn.enable` → protonvpn from AUR (see Task 21)
  - `greetd.enable` → greetd via pacman (see Task 20)
  - `styling.enable` → Handled by stylix standalone in Task 16

  **Station-Specific Overrides**:
  - Terminal opacity: 0.85
  - Swaylock: disabled
  - Hypridle: disabled
  - Hyprland gaps: 0
  - Workspace config: 5 workspaces on HDMI-A-1, 5 on DP-1
  - Workspace gaps: 0 100 200 100
  - Monitor config: HDMI-A-1 (3840x2160@60), DP-1 (1920x1080@120)
  - Remote tmux sessions: vnpc-21 (odin@vnpc-21), laptop (none@laptop)
  - `wayland.windowManager.hyprland.package = null` — Use system Hyprland from pacman, not Nix

  **Critical for Arch**:
  - Set `wayland.windowManager.hyprland.package = null` or equivalent to disable Nix Hyprland install
  - GPU apps that need nixGL: document which ones (Kitty, Chromium, etc.) — actual wrapping may need investigation
  - Set `home.username`, `home.homeDirectory`, `home.stateVersion`

  **Must NOT do**:
  - Change any settings from current NixOS station config — pixel-identical
  - Add new packages or modules not currently enabled
  - Remove `nixosConfigurations.station` from the flake

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 16, 17, 18 after dependencies met)
  - **Parallel Group**: Wave 4 (with Tasks 16, 17, 18)
  - **Blocks**: Task 19 (full evaluation)
  - **Blocked By**: Tasks 2, 3, 9-14 (all modules refactored)

  **References**:

  **Pattern References**:
  - `hosts/station/default.nix` — THE source of truth for all station-specific settings; replicate EVERY override
  - `profiles/base.nix` — Default module enables; copy the full enable list
  - `profiles/desktop.nix` — Desktop profile additions (acpid, etc.)
  - `profiles/hardware/nvidia.nix` — NVIDIA settings (some are NixOS-only, note which ones are HM-relevant)

  **WHY Each Reference Matters**:
  - `hosts/station/default.nix` — Contains ALL the station-specific overrides (monitors, workspaces, gaps, opacity, disabled services). Missing any of these breaks the "pixel-identical" requirement.
  - `profiles/base.nix` — The full list of `.enable = true` options. Must enable ALL of them in the standalone config.

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Complete station-arch evaluates
    Tool: Bash
    Preconditions: All modules refactored (Tasks 9-14), station-arch home.nix populated
    Steps:
      1. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
      2. Run `nix build .#homeConfigurations."none@station".activationPackage --dry-run 2>&1`
    Expected Result: Both succeed without errors
    Failure Indicators: Missing module, wrong option, evaluation error
    Evidence: .sisyphus/evidence/task-15-full-station-eval.txt

  Scenario: NixOS station still evaluates (not removed)
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
    Expected Result: Success — station NixOS config preserved
    Evidence: .sisyphus/evidence/task-15-nixos-station-preserved.txt
  ```

  **Commit**: YES
  - Message: `feat(station-arch): add full standalone HM configuration`
  - Files: `hosts/station-arch/home.nix`
  - Pre-commit: `nix eval .#homeConfigurations."none@station".activationPackage.drvPath && nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath`

---

- [ ] 16. Stylix standalone theming configuration

  **What to do**:
  Based on Task 4 validation results, configure stylix in the station-arch standalone config:
  - Import `inputs.stylix.homeModules.stylix` in station-arch
  - Set `stylix.enable = true`
  - Set `stylix.base16Scheme` to Nord (`"${pkgs.base16-schemes}/share/themes/nord.yaml"`)
  - Set `stylix.polarity = "dark"`
  - Set `stylix.image` to wallpaper path
  - Set cursor: name, package, size (20)
  - Set font configuration matching current NixOS setup
  - Set opacity: terminal = 0.85 (station override), other app opacities as configured
  - Set `stylix.autoEnable = true`

  **If Task 4 found stylix doesn't work standalone**: Fall back to manual theming:
  - GTK theme via `home.file.".config/gtk-3.0/settings.ini"` and `gtk.theme`
  - Qt theme via environment variables
  - Cursor via `home.pointerCursor`
  - Fonts via `fonts.fontconfig`

  **Must NOT do**:
  - Change the theme from Nord
  - Change polarity from dark
  - Change opacity from 0.85
  - Redesign the theming system

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 15, 17, 18)
  - **Blocks**: Task 19
  - **Blocked By**: Task 4 (stylix validation), Task 14 (module index files)

  **References**:

  **Pattern References**:
  - `modules/nixos/styling.nix` — ALL current stylix options; replicate in standalone context
  - `profiles/base.nix` — Default styling values: theme="nord", polarity="dark", opacity.terminal=0.90, cursor.size=20, autoEnable=true
  - `hosts/station/default.nix` — Station override: `styling.opacity.terminal = 0.85`

  **External References**:
  - Stylix standalone HM config: https://danth.github.io/stylix/

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Stylix evaluates in station-arch config
    Tool: Bash
    Steps:
      1. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: No stylix-related errors
    Evidence: .sisyphus/evidence/task-16-stylix-eval.txt
  ```

  **Commit**: YES (groups with Task 15)
  - Message: `feat(station-arch): add stylix + sops standalone integration`
  - Files: `hosts/station-arch/home.nix` (stylix section)

---

- [ ] 17. SOPS standalone secrets configuration + path migration

  **What to do**:
  Based on Task 5 validation results, configure SOPS in station-arch:
  - Import `inputs.sops-nix.homeManagerModules.sops` in station-arch
  - Set `sops.age.keyFile = "/home/none/.config/sops/age/keys.txt"`
  - Define secrets matching current station config (from `secrets/general.yaml` and `secrets/station.yaml`)
  - **CRITICAL PATH CHANGE**: Standalone SOPS decrypts to `/run/user/1000/secrets/` not `/run/secrets/`
  - Update any module that reads from `/run/secrets/` — specifically `modules/home-manager/cli/mcp.nix` which reads `GITHUB_PERSONAL_ACCESS_TOKEN`
  - The path update in `mcp.nix` should be conditional: use `/run/secrets/` when in NixOS mode, `/run/user/1000/secrets/` in standalone mode (or make it configurable)

  **Must NOT do**:
  - Change secret values
  - Add new secrets not in current config
  - Remove secrets from NixOS config

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 15, 16, 18)
  - **Blocks**: Task 19
  - **Blocked By**: Task 5 (SOPS validation), Task 14 (module index files)

  **References**:

  **Pattern References**:
  - `modules/nixos/secrets.nix` — Current NixOS SOPS config; defines default `sops.defaultSopsFile = ../../secrets/secrets.yaml`
  - `hosts/station/default.nix` — Station's SOPS config overrides `sops.defaultSopsFile` to `secrets/general.yaml` (NOTE: this file does NOT exist in repo — likely a stale reference; the actual shared secrets file is `secrets/secrets.yaml`). Also sets `sops.age.keyFile`
  - `modules/home-manager/cli/mcp.nix` — Reads `/run/secrets/github_token`; MUST update path
  - `secrets/general.yaml` — Shared secrets file path (don't read contents)
  - `secrets/station.yaml` — Station secrets file path (don't read contents)

  **WHY Each Reference Matters**:
  - `modules/nixos/secrets.nix` — Defines which secrets are decrypted (default sopsFile is `secrets/secrets.yaml`); same secrets needed in standalone. For station-arch standalone, use `secrets/secrets.yaml` (shared) and `secrets/station.yaml` (host-specific)
  - `mcp.nix` — The known module that hardcodes `/run/secrets/` path; must be updated for standalone compatibility

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: SOPS evaluates in station-arch config
    Tool: Bash
    Steps:
      1. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
    Expected Result: No SOPS-related errors
    Evidence: .sisyphus/evidence/task-17-sops-eval.txt

  Scenario: MCP module uses correct paths per mode
    Tool: Bash
    Steps:
      1. Read `modules/home-manager/cli/mcp.nix`
      2. Verify the GITHUB_PERSONAL_ACCESS_TOKEN path is configurable or mode-aware
      3. Run NixOS eval to verify no regression
    Expected Result: Path resolves correctly in both modes
    Evidence: .sisyphus/evidence/task-17-mcp-paths.txt
  ```

  **Commit**: YES (groups with Task 16)
  - Message: `feat(station-arch): add stylix + sops standalone integration`
  - Files: `hosts/station-arch/home.nix` (sops section), `modules/home-manager/cli/mcp.nix`

---

- [ ] 18. Nix daemon + build server configuration documentation

  **What to do**:
  Document how to configure station as a Nix remote builder on Arch Linux:
  - Nix daemon installation and systemd service
  - `nix.conf` settings: experimental-features, trusted-users, max-jobs, etc.
  - nix-serve setup (binary cache HTTP server on port 5000)
  - **Signing key preservation**: Find where the nix-serve signing key is stored on current NixOS station, document how to copy it to Arch
  - Signing key is referenced by other hosts as `station:IH2kzUkYwmAVyk7J1XIgfIMw4d2vb5xA8ID8Ns9m7Xc=`
  - systemd timer for nix garbage collection (replacing NixOS `nix.gc.automatic`)
  - `/etc/nix/nix.conf` configuration for Arch
  - Document how laptop and vnpc-21 connect to station's build cache (no changes needed if IP stays 10.10.10.10)

  **Must NOT do**:
  - Create automation scripts — document manual steps in markdown
  - Change other hosts' build cache configurations (IP stays the same)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 15, 16, 17)
  - **Blocks**: Task 19
  - **Blocked By**: Task 14 (module system working)

  **References**:

  **Pattern References**:
  - `hosts/station/default.nix` — Current distributed build config; find `nix.buildMachines`, `nix-serve` settings
  - `hosts/laptop/default.nix` — How laptop references station as substituter (to verify URL/key)
  - `modules/nixos/general.nix` — Nix configuration settings (experimental-features, gc, trusted-users)

  **External References**:
  - Nix on Arch: https://wiki.archlinux.org/title/Nix
  - nix-serve: https://github.com/edolstra/nix-serve

  **WHY Each Reference Matters**:
  - `hosts/station/default.nix` — Contains the current build server config that must be replicated
  - `hosts/laptop/default.nix` — Shows how clients reference station; confirms URL and key format

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Build server docs cover all required sections
    Tool: Bash
    Steps:
      1. Check docs file exists with sections: nix-daemon, nix.conf, nix-serve, signing key, garbage collection, client configuration
    Expected Result: All sections present with specific commands
    Evidence: .sisyphus/evidence/task-18-build-docs.txt
  ```

  **Commit**: YES
  - Message: `feat(station-arch): add nix-daemon build server documentation`
  - Files: `docs/station-arch-build-server.md`

---

- [ ] 19. Full evaluation test — all homeConfigurations + nixosConfigurations

  **What to do**:
  Final integration test after all Wave 4 work:
  - Evaluate `homeConfigurations."none@station"` — must succeed
  - Build `homeConfigurations."none@station"` dry-run — must succeed
  - Evaluate ALL 8 `nixosConfigurations` — must succeed (no regression)
  - Run `nix flake check` — must pass
  - Compare NixOS station derivation path to pre-migration value — must be unchanged

  **Must NOT do**:
  - Make any code changes — pure verification
  - Skip any host

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (after Tasks 15-18)
  - **Blocks**: Wave FINAL
  - **Blocked By**: Tasks 15, 16, 17, 18

  **References**:
  - `parts/hosts.nix` — Complete list of nixosConfigurations to evaluate

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Complete evaluation suite passes
    Tool: Bash
    Steps:
      1. Run `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
      2. Run `nix build .#homeConfigurations."none@station".activationPackage --dry-run 2>&1`
      3. Run `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath 2>&1`
      4. Run `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath 2>&1`
      5. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1`
      6. Run `nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath 2>&1`
      7. Run `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath 2>&1`
      8. Run `nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath 2>&1`
      9. Run `nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath 2>&1`
      10. Run `nix eval .#nixosConfigurations.spiders.config.system.build.toplevel.drvPath 2>&1`
      11. Run `nix eval .#nixosConfigurations.installer.config.system.build.toplevel.drvPath 2>&1`
      12. Run `nix flake check 2>&1`
    Expected Result: ALL 12 commands succeed (0 failures)
    Failure Indicators: Any evaluation failure = regression or integration bug
    Evidence: .sisyphus/evidence/task-19-full-eval-suite.txt
  ```

  **Commit**: NO (verification only)

---

- [x] 20. Arch base system setup guide

  **What to do**:
  Create `docs/station-arch-setup.md` — comprehensive Arch Linux installation guide specific to station's hardware:

  **Sections to include**:
  1. **Pre-installation**: Download Arch ISO, create bootable USB
  2. **Partitioning**: Replicate current layout (NVMe SSD, ext4 root, swap partition) — or recommend improvements (BTRFS for snapshots)
  3. **Base install**: `pacstrap`, locale, timezone, hostname (station)
  4. **Bootloader**: GRUB on `/dev/nvme0n1` with os-prober (dual boot if user keeps Windows)
  5. **Networking**: Static IP 10.10.10.10/24 on enp82s0 via systemd-networkd, gateway 10.10.10.1, DNS 10.10.10.1 + 1.1.1.1
  6. **User setup**: Create user `none`, groups (wheel, docker, libvirt, plugdev, dialout), zsh shell, SSH keys
  7. **NVIDIA drivers**: `nvidia-dkms` + `linux-lts` kernel (for stability), kernel parameters (`nvidia-drm.modeset=1`)
  8. **Display server**: Hyprland from pacman, greetd display manager, create `/usr/share/wayland-sessions/hyprland.desktop`
  9. **Nix installation**: Multi-user install, enable flakes, configure daemon
  10. **Home-manager**: Install standalone, link to flake
  11. **Essential system packages**: Via pacman — list ALL needed packages (xdg-desktop-portal-hyprland, polkit, etc.)
  12. **Sleep/suspend prevention**: `systemctl mask sleep.target suspend.target hibernate.target`
  13. **Environment variables**: `LOCALE_ARCHIVE`, `XDG_DATA_DIRS` for Nix fonts, `PATH` ordering (pacman vs Nix)
  14. **nixGL setup**: For any Nix-installed GUI apps needing GPU acceleration

  **Must NOT do**:
  - Create automation scripts — markdown documentation only
  - Make assumptions about user's physical access to machine

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Tasks 21, 22)
  - **Blocks**: Wave FINAL (F1)
  - **Blocked By**: None (can start as early as Wave 1, independent of code changes)

  **References**:

  **Pattern References**:
  - `hosts/station/default.nix` — ALL station-specific settings that need Arch equivalents (networking, user, NVIDIA, grub)
  - `hosts/station/hardware-configuration.nix` — Hardware details (NVMe, kernel modules, network interfaces)
  - `profiles/hardware/nvidia.nix` — NVIDIA driver config (kernel params, driver package, settings)

  **External References**:
  - Arch Wiki Installation Guide: https://wiki.archlinux.org/title/Installation_guide
  - Arch Wiki NVIDIA: https://wiki.archlinux.org/title/NVIDIA
  - Arch Wiki Hyprland: https://wiki.archlinux.org/title/Hyprland
  - Arch Wiki systemd-networkd: https://wiki.archlinux.org/title/Systemd-networkd

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Setup guide has all required sections
    Tool: Bash
    Steps:
      1. Read docs/station-arch-setup.md
      2. Check for sections: partitioning, networking (with IP 10.10.10.10), NVIDIA, Hyprland, greetd, Nix, home-manager, nixGL
    Expected Result: All sections present with specific commands
    Evidence: .sisyphus/evidence/task-20-setup-guide-sections.txt
  ```

  **Commit**: YES (groups with Tasks 21, 22)
  - Message: `docs(station-arch): add Arch Linux setup guide`
  - Files: `docs/station-arch-setup.md`

---

- [x] 21. System services + pacman ownership guide

  **What to do**:
  Create `docs/station-arch-services.md` — guide for installing and configuring ALL system services on Arch:

  **Pacman vs Nix Ownership Table** (include in doc):

  | Component | Owner | Package | Notes |
  |-----------|-------|---------|-------|
  | Kernel | pacman | `linux-lts` | Stable for NVIDIA dkms |
  | NVIDIA drivers | pacman | `nvidia-dkms` | dkms for kernel compat |
  | Hyprland | pacman | `hyprland` | System WM |
  | Greetd | pacman | `greetd` | Display manager |
  | Docker | pacman | `docker` | System daemon |
  | QEMU/KVM | pacman | `qemu-full libvirt virt-manager` | System virtualization |
  | Tailscale | pacman | `tailscale` | System VPN |
  | Netbird | AUR | `netbird` | Mesh VPN |
  | Syncthing | pacman | `syncthing` | File sync |
  | Sunshine | AUR | `sunshine` | Game streaming |
  | SSH | pacman | `openssh` | System daemon |
  | Ollama | pacman/AUR | `ollama-cuda` | GPU inference |
  | PostgreSQL | pacman | `postgresql` | Database |
  | PipeWire | pacman | `pipewire pipewire-pulse wireplumber` | Audio |
  | Bluetooth | pacman | `bluez bluez-utils` | Bluetooth stack |
  | Polkit | pacman | `polkit polkit-gnome` | Privilege escalation |
  | XDG Portals | pacman | `xdg-desktop-portal-hyprland xdg-desktop-portal-gtk` | Screensharing |
  | Nix | pacman/manual | `nix` | Package manager |
  | All user CLI tools | Nix/HM | (via home-manager) | Managed declaratively |
  | All user GUI apps | Nix/HM | (via home-manager) | May need nixGL |
  | Theming | Nix/HM | (via stylix) | HM-managed |

  **For EACH system service**, document:
  1. Installation command (`pacman -S` or AUR helper)
  2. Configuration file location and required settings
  3. Systemd service enable/start commands
  4. Service-specific notes (e.g., Docker: add `none` to docker group; Ollama: CUDA setup)

  **Special sections**:
  - ProtonVPN setup on Arch
  - Open WebUI setup (Docker container or native)
  - Gaming: Heroic Launcher + Bottles (from Flathub or AUR)
  - Printing: CUPS setup
  - PAM configuration for swaylock (even though disabled, document for future)

  **Must NOT do**:
  - Create automation scripts
  - Change any service configurations from current NixOS setup

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Tasks 20, 22)
  - **Blocks**: Wave FINAL
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `hosts/station/default.nix` — All enabled services and their configs
  - `profiles/base.nix` — Default enabled services list
  - `modules/nixos/` — Each NixOS module shows what system config is needed

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: All services documented
    Tool: Bash
    Steps:
      1. Read docs/station-arch-services.md
      2. Check for: Docker, Ollama, PostgreSQL, Tailscale, Netbird, Syncthing, Sunshine, SSH, QEMU, PipeWire, Bluetooth, greetd
    Expected Result: All services have install + configure + enable sections
    Evidence: .sisyphus/evidence/task-21-services-guide.txt
  ```

  **Commit**: YES (groups with Task 20)
  - Message: `docs(station-arch): add Arch Linux setup guide`
  - Files: `docs/station-arch-services.md`

---

- [x] 22. Data backup/migration checklist

  **What to do**:
  Create `docs/station-arch-backup.md` — comprehensive checklist of EVERYTHING to back up before wiping NixOS:

  **Critical Data**:
  - [ ] SOPS age key: `/home/none/.config/sops/age/keys.txt`
  - [ ] SSH keys: `/home/none/.ssh/` (private + public keys, config, known_hosts)
  - [ ] SSH host keys: `/etc/ssh/ssh_host_*` (restore to avoid MITM warnings on other machines)
  - [ ] nix-serve signing key: Find location (check NixOS config for `nix.sshServe` or `services.nix-serve.secretKeyFile`)
  - [ ] Syncthing identity: `/home/none/.config/syncthing/` (cert.pem, key.pem, config.xml)
  - [ ] PostgreSQL databases: `sudo -u postgres pg_dumpall > /tmp/pg_backup.sql`
  - [ ] Docker volumes: `docker volume ls` then `docker volume inspect` for data locations
  - [ ] Ollama models: `~/.ollama/models/` or wherever configured (potentially tens of GB)
  - [ ] GPG keys: `~/.gnupg/` if any
  - [ ] Tailscale state: Usually managed by tailscale daemon — may need re-auth
  - [ ] Netbird state: May need re-auth
  - [ ] Git repos: Ensure all local repos are pushed to remote
  - [ ] Syncthing files: Verify all files are synced before wipe
  - [ ] 1Password: Cloud-based — just need to re-login
  - [ ] Browser profiles: Synced via browser accounts
  - [ ] Home directory: Consider backing up entire `/home/none/` if no separate partition

  **Verification Steps**:
  - For each backup item: verify the backup is readable/restorable BEFORE wiping
  - Test PostgreSQL restore: `psql -f pg_backup.sql` in a temp db
  - Test SSH key: verify fingerprint matches

  **Post-Migration Restore Order**:
  1. SOPS age key (needed for home-manager secrets)
  2. SSH keys (needed for server access)
  3. SSH host keys (prevent MITM warnings)
  4. nix-serve signing key (restore build cache)
  5. Syncthing identity (keep device ID)
  6. PostgreSQL data
  7. Docker volumes
  8. Ollama models

  **Must NOT do**:
  - Create backup scripts — checklist only
  - Include secret values in the document

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Tasks 20, 21)
  - **Blocks**: Wave FINAL
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `hosts/station/default.nix` — All services with state to back up
  - `modules/nixos/secrets.nix` — SOPS configuration, key paths
  - `secrets/station.yaml` — Station secrets file reference (path only)

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Backup checklist covers all critical data
    Tool: Bash
    Steps:
      1. Read docs/station-arch-backup.md
      2. Check for: SOPS key, SSH keys, SSH host keys, nix-serve key, Syncthing, PostgreSQL, Docker, Ollama
    Expected Result: All items present with exact file paths and backup commands
    Evidence: .sisyphus/evidence/task-22-backup-checklist.txt
  ```

  **Commit**: YES (groups with Tasks 20, 21)
  - Message: `docs(station-arch): add Arch Linux setup guide`
  - Files: `docs/station-arch-backup.md`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (nix eval outputs, read config files). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan. Verify `nixosConfigurations.station` still exists (not removed). Verify all documentation files have required sections.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `nix flake check` and `nix fmt -- --check .`. Review all changed/new Nix files for: unused imports, inconsistent patterns, hardcoded paths that should be variables, missing `lib.mkIf` guards. Check that module compatibility layer is clean (no hacks, no `builtins.tryEval`). Verify all modules follow the same refactoring pattern consistently.
  Output: `Flake Check [PASS/FAIL] | Format [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real QA — Full Nix Eval Suite** — `unspecified-high`
  Run ALL these commands and capture output:
  - `nix eval .#homeConfigurations."none@station".activationPackage.drvPath`
  - `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath`
  - `nix build .#homeConfigurations."none@station".activationPackage --dry-run`
  ALL must succeed. Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Evaluations [N/N pass] | Build [PASS/FAIL] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git diff main...HEAD`). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance: no module behavior changes, no theme changes, no server config changes, no removed nixosConfigurations.station. Flag unaccounted files.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

All commits on branch `station-arch-migration`:

1. `feat(flake): add homeConfigurations output for standalone home-manager` — parts/home-manager-standalone.nix, hosts/station-arch/home.nix skeleton
2. `refactor(hm): add standalone compatibility layer for HM modules` — Compatibility shim or two-layer architecture
3. `refactor(hm): pilot standalone compat — git, hyprland, mcp modules` — 3 pilot modules validated in both modes
4. `refactor(hm): migrate cli modules to dual-mode compatibility` — All cli/ modules
5. `refactor(hm): migrate neovim submodules to dual-mode compatibility` — All neovim/ submodules
6. `refactor(hm): migrate app modules to dual-mode compatibility` — All app/ modules
7. `refactor(hm): migrate desktop + misc modules to dual-mode compatibility` — desktop/ and misc/ modules
8. `refactor(hm): update module index files for standalone support` — default.nix files
9. `feat(station-arch): add full standalone HM configuration` — Complete station-arch host config
10. `feat(station-arch): add stylix + sops standalone integration` — Theming and secrets
11. `feat(station-arch): add nix-daemon build server documentation` — Build server config
12. `docs(station-arch): add Arch Linux setup guide` — Base system, services, backup checklist

---

## Success Criteria

### Verification Commands
```bash
# Standalone HM evaluates successfully
nix eval .#homeConfigurations."none@station".activationPackage.drvPath
# Expected: "/nix/store/...-home-manager-generation"

# All NixOS hosts still evaluate (no regression) — note VNPC-21 is capitalized, 9 total
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.spiders.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.installer.config.system.build.toplevel.drvPath
# Expected: "/nix/store/...-nixos-system-<host>-..." (9 hosts, all succeed)

# Standalone HM builds
nix build .#homeConfigurations."none@station".activationPackage --dry-run
# Expected: "will build derivation..." (no errors)

# Flake is valid
nix flake check
# Expected: no errors
```

### Final Checklist
- [ ] `homeConfigurations."none@station"` evaluates and builds
- [ ] All existing `nixosConfigurations` evaluate unchanged
- [ ] `nixosConfigurations.station` preserved (not removed)
- [ ] All 50+ HM modules work in both modes
- [ ] Stylix Nord theming in standalone config
- [ ] SOPS secrets in standalone config with correct paths
- [ ] Build server documentation complete
- [ ] Arch setup guide covers all system services
- [ ] Data backup checklist complete
- [ ] Zero changes to server configs
- [ ] Zero changes to laptop/VNPC-21 configs
