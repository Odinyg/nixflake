# Mutable Override Layer for Hyprland, Waybar, and Rofi

## TL;DR

> **Quick Summary**: Add a mutable dotfile layer on top of Nix-managed desktop configs so Hyprland, Waybar, and Rofi can be tweaked live without rebuilding. Core settings stay in Nix; override files take priority and apply on reload/restart.
>
> **Deliverables**:
> - Hyprland `source` directive → `~/.config/hypr/overrides.conf` (instant reload)
> - Waybar fully mutable `~/.config/waybar/` with Nix base reference at `~/.config/waybar-base/`
> - Rofi fully mutable `~/.config/rofi/` with Nix base reference at `~/.config/rofi-base/`
> - Justfile commands: `just theme-reset <app>` and `just theme-promote <app>`
>
> **Estimated Effort**: Short
> **Parallel Execution**: YES — 2 waves
> **Critical Path**: Task 1 + Task 2 (parallel) → Task 3 → Final Verification

---

## Context

### Original Request
User finds it annoying to rebuild NixOS every time they want to tweak Hyprland theming, gaps, decorations, or bar layout. They want core settings managed by Nix for consistency, with a secondary mutable layer that overrides the base — allowing live experimentation that can later be promoted into the Nix config.

### Interview Summary
**Key Discussions**:
- **Target apps**: Hyprland, Waybar, Rofi (explicitly excluded Kitty, Stylix/colors)
- **Hyprland approach**: `source = ~/.config/hypr/overrides.conf` at end of generated config — Hyprland's last-write-wins for scalar settings
- **Waybar approach**: Full mutable — stop Nix-managing `~/.config/waybar/`, keep base as read-only reference, user owns the actual config directory
- **Rofi approach**: Same full-mutable pattern as Waybar
- **Override granularity**: Single override file for Hyprland (not per-concern)
- **Helper scripts**: Yes — `just theme-reset <app>` and `just theme-promote <app>` in justfile

### Research Findings
- Hyprland config is generated via `wayland.windowManager.hyprland.settings` (Nix attrs) in `default.nix`
- `monitors.nix` and `hosts/station/default.nix` both write to `extraConfig` — the source line MUST use `lib.mkAfter` to guarantee it appears last
- Waybar is managed as `xdg.configFile."waybar".source = ./config/waybar` in `packages.nix` (read-only symlink to Nix store)
- Rofi has 3 interdependent files: `config.rasi` → `@theme "nord"` → `nord.rasi` → `@import "rounded-common.rasi"` — all 3 must move to mutable together
- Waybar directory contains `modules/storage.sh` (executable) — copy must preserve permissions (`cp -a`)
- No existing `home.activation` usage in the codebase — this is a new pattern
- Hosts use different users: laptop/station = `none`, vnpc-21 = `odin` — all paths must use `$HOME`, not hardcoded

### Metis Review
**Identified Gaps** (addressed):
- `extraConfig` ordering: `source` line must use `lib.mkAfter` to appear after monitor/workspace configs → incorporated
- Rofi has 3 files not 1: all 3 must move to base-copy pattern together → incorporated
- Hyprland `source` errors on missing file: activation script creates placeholder → incorporated
- `theme-promote hyprland` can't auto-convert overrides.conf → Nix attrs: documented as manual-only → incorporated
- Keybindings are array-additive: cannot be overridden via `source`, only added → documented in guardrails
- Station's `lib.mkForce` values render in `settings` before `source`: override correctly wins → no action needed

---

## Work Objectives

### Core Objective
Enable live desktop theming experimentation without NixOS rebuilds, while preserving Nix as the source of truth for core config.

### Concrete Deliverables
- Modified `modules/home-manager/desktop/hyprland/default.nix` — adds `source` directive
- Modified `modules/home-manager/desktop/hyprland/packages.nix` — waybar/rofi → base-copy pattern
- Modified `justfile` — adds theme-reset/theme-promote commands
- New mutable files at runtime: `~/.config/hypr/overrides.conf`, `~/.config/waybar/`, `~/.config/rofi/`

### Definition of Done
- [ ] `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` succeeds
- [ ] `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` succeeds
- [ ] `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath` succeeds
- [ ] Hyprland override file is sourced and changes take effect on `hyprctl reload`
- [ ] Waybar config is mutable real files (not Nix store symlinks) and survives `just rebuild`
- [ ] Rofi config is mutable real files and survives `just rebuild`
- [ ] `just theme-reset` and `just theme-promote` commands work

### Must Have
- `source` line appears AFTER all other `extraConfig` content (monitors, station workspace rules)
- Empty/placeholder `overrides.conf` must not cause Hyprland parse errors
- All 3 rofi files moved together (config.rasi, nord.rasi, rounded-common.rasi)
- Waybar copy preserves `modules/storage.sh` executable bit
- Mutable configs persist through `just rebuild`
- All paths use `$HOME` / `${config.user}`, never hardcoded `/home/none`

### Must NOT Have (Guardrails)
- DO NOT touch `keybindings.nix` — keybindings are array-additive in Hyprland, not overridable via `source`
- DO NOT touch `packages.nix` lines 68-76 (hyprpaper, random-wallpaper.sh, pyprland, hyprshade, shader configs)
- DO NOT introduce `programs.waybar` or `programs.rofi` home-manager modules
- DO NOT modify `hyprpanel.nix`, `services.nix`, or `monitors.nix` (beyond the `source` mechanism)
- DO NOT change station's `lib.mkForce` overrides in `hosts/station/default.nix`
- DO NOT add `theme-promote hyprland` as an automated file-copy command (Nix attrs ≠ flat config)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO (NixOS config — no unit test framework)
- **Automated tests**: None (NixOS config changes are verified via `nix eval` and runtime behavior)
- **Framework**: N/A

### QA Policy
Every task includes agent-executed QA scenarios verified via Bash commands.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **NixOS config**: Use Bash — `nix eval` to verify all 3 hosts evaluate cleanly
- **File verification**: Use Bash — `grep`, `ls -la`, `stat`, `diff` to verify file content and properties
- **Runtime behavior**: Use Bash — `hyprctl`, `diff`, file mutation + rebuild persistence checks

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — independent file changes):
├── Task 1: Hyprland source directive + overrides.conf activation [quick] (default.nix)
└── Task 2: Waybar + Rofi base-copy pattern [quick] (packages.nix)

Wave 2 (After Wave 1 — depends on knowing file structure):
└── Task 3: Justfile theme-reset/theme-promote commands [quick] (justfile)

Wave FINAL (After ALL tasks — 4 parallel reviews):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real QA — rebuild + runtime verification (unspecified-high)
└── F4: Scope fidelity check (deep)
→ Present results → Get explicit user okay
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1    | —         | 3, F*  | 1    |
| 2    | —         | 3, F*  | 1    |
| 3    | 1, 2      | F*     | 2    |
| F1-4 | 1, 2, 3   | —      | FINAL |

### Agent Dispatch Summary

- **Wave 1**: **2 parallel** — T1 → `quick`, T2 → `quick`
- **Wave 2**: **1** — T3 → `quick`
- **FINAL**: **4 parallel** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (grep generated files, check activation scripts). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath`. Review all changed files for: hardcoded paths, missing `lib.mkIf` guards, syntax errors. Check activation scripts for idempotency.
  Output: `Eval laptop [PASS/FAIL] | Eval station [PASS/FAIL] | Eval VNPC-21 [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real QA** — `unspecified-high`
  Run `just rebuild` on the current host. After rebuild verify: `~/.config/hypr/overrides.conf` exists and is writable, `~/.config/waybar/` is a real directory (not symlink) with correct contents, `~/.config/rofi/` is a real directory with all 3 `.rasi` files. Test override persistence: edit a mutable file → `just rebuild` → verify edit survived. Test `just theme-reset` and `just theme-promote` commands.
  Output: `Rebuild [PASS/FAIL] | Override files [N/N] | Persistence [PASS/FAIL] | Just commands [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git diff`). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance: keybindings.nix untouched, packages.nix lines 68-76 untouched, no programs.waybar/programs.rofi, no station mkForce changes. Flag any unaccounted changes.
  Output: `Tasks [N/N compliant] | Must NOT [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **After Wave 1**: `feat(desktop): add mutable override layer for hyprland, waybar, and rofi` — default.nix, packages.nix
- **After Wave 2**: `feat(justfile): add theme-reset and theme-promote commands` — justfile

---

## Success Criteria

### Verification Commands
```bash
# All 3 hosts evaluate cleanly
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath

# After rebuild: override mechanism works
grep "source" ~/.config/hypr/hyprland.conf  # Expected: source line present
ls -la ~/.config/waybar/config               # Expected: regular file, not symlink
ls -la ~/.config/rofi/config.rasi            # Expected: regular file, not symlink

# Mutable edit persists through rebuild
echo "# test" >> ~/.config/waybar/style.css && just rebuild && tail -1 ~/.config/waybar/style.css  # Expected: "# test"
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All 3 hosts evaluate cleanly
- [ ] Override workflow: edit → reload → see change (no rebuild)
- [ ] Justfile theme-reset/theme-promote functional
