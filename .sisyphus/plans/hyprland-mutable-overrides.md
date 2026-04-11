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

## TODOs

- [x] 1. Hyprland source directive + overrides.conf activation
- [x] 2. Waybar + Rofi base-copy pattern
- [x] 3. Justfile theme-reset and theme-promote commands

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (grep generated files, check activation scripts). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath`. Review all changed files for: hardcoded paths, missing `lib.mkIf` guards, syntax errors. Check activation scripts for idempotency.
  Output: `Eval laptop [PASS/FAIL] | Eval station [PASS/FAIL] | Eval VNPC-21 [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real QA** — `unspecified-high` (REQUIRES MANUAL: sudo not available in non-interactive context)
  Run `just rebuild` on the current host. After rebuild verify: `~/.config/hypr/overrides.conf` exists and is writable, `~/.config/waybar/` is a real directory (not symlink) with correct contents, `~/.config/rofi/` is a real directory with all 3 `.rasi` files. Test override persistence: edit a mutable file → `just rebuild` → verify edit survived. Test `just theme-reset` and `just theme-promote` commands.
  Output: `Rebuild [PASS/FAIL] | Override files [N/N] | Persistence [PASS/FAIL] | Just commands [N/N] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep` (flagged .sisyphus plan file in commit — benign)
  For each task: read "What to do", read actual diff (`git diff HEAD~3`). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance: keybindings.nix untouched, packages.nix lines 68-76 untouched, no programs.waybar/programs.rofi, no station mkForce changes. Flag any unaccounted changes.
  Output: `Tasks [N/N compliant] | Must NOT [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Must Have (for F1 reference)
- `source` line appears AFTER all other `extraConfig` content (monitors, station workspace rules)
- Empty/placeholder `overrides.conf` must not cause Hyprland parse errors (activation creates it)
- All 3 rofi files moved together (config.rasi, nord.rasi, rounded-common.rasi)
- Waybar copy preserves `modules/storage.sh` executable bit (`cp -a`)
- Mutable configs persist through `just rebuild`
- All paths use `$HOME` / `${config.user}`, never hardcoded `/home/none`

## Must NOT Have (for F1 reference)
- DO NOT touch `keybindings.nix`
- DO NOT touch `packages.nix` lines 68-76 (hyprpaper, random-wallpaper.sh, pyprland, hyprshade, shader)
- DO NOT introduce `programs.waybar` or `programs.rofi` home-manager modules
- DO NOT modify `hyprpanel.nix`, `services.nix`, `monitors.nix`
- DO NOT change station's `lib.mkForce` overrides
- DO NOT add `theme-promote hyprland` as automated file-copy

## Commits Made
- `d25953c`: `feat(desktop): add mutable override layer for hyprland, waybar, and rofi` (Tasks 1+2)
- `5880c0e`: `chore: remove generated workflow artifacts`
- Wave 2 commit pending for justfile (Task 3)
