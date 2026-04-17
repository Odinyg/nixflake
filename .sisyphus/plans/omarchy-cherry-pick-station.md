# Omarchy Cherry-Pick for Station

## TL;DR

> **Quick Summary**: Port 9 curated omarchy-inspired UX helpers (color picker, clipboard history, emoji picker, launch-or-focus, webapp installer, window pop, power menu, semantic CLI namespace, animation toggle) to the NixOS `station` host as a single opt-in home-manager module. Zero changes to laptop/VNPC-21. Zero changes to Stylix. Additive Hyprland keybinds only.
>
> **Deliverables**:
> - New module `modules/home-manager/desktop/omo-helpers.nix` with `omo-helpers.enable` flag
> - 7 `omo-*` shell scripts as `writeShellScriptBin` entries
> - Waybar power-icon module (file-based JSON + Catppuccin CSS)
> - Hyprland animation toggle via sourced state file (mutable, persistent)
> - Rofi-based clipboard + emoji + power pickers reusing existing Nord theme
> - `cliphist` user service for clipboard history
> - Station host enables the module; other hosts unaffected
>
> **Estimated Effort**: Medium (9 items, ~1-2 days of NixOS module work)
> **Parallel Execution**: YES — 4 waves
> **Critical Path**: T1 (validation) → T2 (skeleton) → T4/T5 (scripts) → T11 (keybinds + legacy bind removal) → F1-F4

---

## Context

### Original Request
> "https://github.com/basecamp/omarchy Lets look trough this and see if there is anything cool and usefull we can steal for our setup"

### Interview Summary
**Adoption style**: Cherry-pick gems (curated 8-10 items) — minimal disruption.
**Host scope**: `station` testbed only. Laptop / VNPC-21 explicitly out-of-scope.
**Hard constraints**: Keep current Hyprland keybindings (new keys must be additive); keep Stylix as single source of truth for theming.
**CLI prefix**: `omo-*`.
**Webapp browser**: Zen (primary desktop browser).
**Power menu trigger**: keybind (Super+Shift+E) + waybar click.
**Animations**: Off-by-default; ship `omo-toggle-animations` toggle command.

### Research Findings (from explore + librarian)
- **Rofi variant**: `pkgs.rofi` (X11, runs via XWayland). No emoji plugin present. Must use `pkgs.rofi-emoji` (matching X11 variant), NOT `rofi-emoji-wayland`. `packages.nix:69`.
- **Waybar/Rofi config**: mutable — copied ONCE at activation from `-base` directory. Changes won't auto-propagate to existing installs. Requires `rm -rf ~/.config/waybar && nixos-rebuild switch` after changes. `packages.nix:98-121`.
- **Waybar theme**: Catppuccin Macchiato (`style.css` imports `macchiato.css`). Rofi uses Nord. Two separate palettes. New waybar CSS must use `@red`/`@maroon` etc.
- **Hyprland source= pattern**: Already proven via `source = ~/.config/hypr/overrides.conf` with `extraConfig = lib.mkAfter ...` + activation script creating the file if missing. `default.nix:160-188`. Reuse identical pattern for animations.conf.
- **Animations state**: `animations.enabled = false` at `default.nix:82` with curves pre-defined (lines 83-91). Toggle only needs to flip `animations:enabled = true`; curves stay loaded in-process.
- **Existing Super+W bind**: `"$mainMod, W, exec, zen-beta"` at `keybindings.nix:34`.
- **Existing Super+E bind**: `"$mainMod, E, exec, thunar"` at `keybindings.nix:43`.
- **Available keys**: Super+Shift+C, +V, +E, +O, Super+. all free (confirmed against existing bind inventory).
- **Station specifics**: `hypridle` + `swaylock` disabled (`hosts/station/default.nix:141-142`); suspend + hibernation disabled (`AllowSuspend=no`, lines 86-91). Lock and suspend in the power menu must handle this gracefully.
- **Station monitors**: DP-2 is 2560×1440 **rotated 270°** (effective 1440×2560 portrait) + HDMI-A-2 is 3840×2160 (`hosts/station/default.nix:210-212`). Window sizing must be percentage-based, queried via `hyprctl monitors -j`.
- **Zen browser**: flake input `github:0xc000022070/zen-browser-flake`, executable `zen-beta`. `--name` / `--app` flags support UNVERIFIED. T1 tests before committing webapp-install to this approach.

### Metis Review
**Identified Gaps** (addressed):
- Rofi variant mismatch → documented; plan uses `pkgs.rofi-emoji` (X11).
- Zen `--name` flag unverified → T1 validation task blocks T8 until confirmed.
- Duplicate Super+W/E binds during transition → bind removal + addition happen in the SAME task (T11) to prevent broken intermediate state.
- Station's disabled lock/suspend → power menu respects host config (see T12).
- Hyprland `source =` with missing file → activation script uses `[ ! -f ... ]` guard (mirrors existing `initHyprlandOverrides` pattern).
- `hyprctl keyword source` is additive, cannot "un-set" → toggle script uses `hyprctl reload`.
- Waybar mutable config gotcha → T16 includes explicit reset step.
- Nerd Font vs Unicode power glyph → plan specifies `` (U+F011, Nerd Font `nf-fa-power_off`), not `⏻`.
- Cliphist interaction with wl-clip-persist → documented as acceptable; minor duplicate risk.
- Window-pop on tiled vs floating vs fullscreen → script detects state and branches.

---

## Work Objectives

### Core Objective
Ship a single opt-in NixOS home-manager module (`omo-helpers`) that adds 9 curated omarchy-inspired desktop UX improvements to the `station` host, leaving every other host untouched, without altering existing keybindings, rofi themes, or Stylix theming.

### Concrete Deliverables
- `modules/home-manager/desktop/omo-helpers.nix` — new module with `options.omo-helpers.enable`
- `modules/home-manager/desktop/default.nix` — updated to import `./omo-helpers.nix` (if desktop/default.nix exists; else imports chain via `modules/home-manager/default.nix`)
- `hosts/station/default.nix` — `omo-helpers.enable = true;`
- `omo-*` shell scripts in `$HOME/.nix-profile/bin/` when module enabled:
  - `omo-launch-or-focus`, `omo-webapp-install`, `omo-window-pop`, `omo-power-menu`, `omo-toggle-animations`, `omo-clipboard-pick`, `omo-emoji-pick`
- `~/.local/state/hypr/animations.conf` (mutable, initialized empty) + `~/.config/hypr/omo-animations-on.conf` (Nix-managed template)
- Station-only waybar patches applied at activation time to the MUTABLE `~/.config/waybar/` copy (adds `custom/power` module + `#custom-power` CSS rule). Shared source files in `modules/home-manager/desktop/hyprland/config/waybar/` are NOT edited — only the deployed copy on station is patched.
- Station-only Hyprland binds injected via `omo-helpers.nix` settings using `lib.mkAfter` — override stock Super+W / Super+E without touching shared `keybindings.nix`.

### Definition of Done
- [ ] `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` succeeds
- [ ] `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` succeeds (no regression)
- [ ] `nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath'` succeeds (no regression — note: flake attr is `VNPC-21` uppercase, see `parts/hosts.nix:37`)
- [ ] All 7 `omo-*` scripts exist in PATH on station after rebuild
- [ ] `hyprctl binds -j` on station shows the 5 new binds (Super+Shift+C/V/O/E + Super+.)
- [ ] `hyprctl binds -j` on station shows Super+W and Super+E pointing to `omo-launch-or-focus`, NOT bare `zen-beta` / `thunar`
- [ ] `systemctl --user is-active cliphist` → `active`
- [ ] Waybar displays the power icon and clicking it invokes `omo-power-menu`
- [ ] F1-F4 final verification wave all approve; user gives explicit OK

### Must Have
- Single flat enable flag: `omo-helpers.enable`. No per-feature sub-options.
- All `omo-*` scripts: max 30 lines each, silent on success (except hyprpicker + power-menu), errors via `notify-send` + `exit 1`.
- Nix interpolation for binary paths in scripts: `${pkgs.jq}/bin/jq` etc.
- Rofi pickers use kill-then-open: `${pkgs.procps}/bin/pkill -x rofi || true; <rofi ...>` — NOT the launcher's toggle pattern.
- Module pattern strictly matches CLAUDE.md idioms: `let cfg = config.omo-helpers; in { options.omo-helpers.enable = lib.mkEnableOption "..."; config = lib.mkIf cfg.enable { home-manager.users.${config.user} = { ... }; }; }`.
- `[ ! -f ... ]` guard on all activation scripts that create mutable state files — preserves user state across rebuilds.
- `omo-toggle-animations` uses `hyprctl reload`, NOT `hyprctl keyword source`.
- Waybar power glyph: Nerd Font `` (U+F011), NOT Unicode `⏻`.
- Waybar CSS uses Catppuccin Macchiato variables (`@red`), NOT Nord hex values.
- Scripts use `$HOME` / `${XDG_STATE_HOME:-$HOME/.local/state}` / `${XDG_DATA_HOME:-$HOME/.local/share}` — never hardcoded `/home/none/`.
- Module is imported from all desktops but only enabled on station. `nix eval` on laptop + VNPC-21 must still succeed.
- Evidence files saved to `.sisyphus/evidence/` per task.

### Must NOT Have (Guardrails)
- No new `.rasi` files. Clipboard + emoji + power-menu pickers reuse existing Nord rofi theme.
- No edits to shared source files: `modules/home-manager/desktop/hyprland/keybindings.nix`, `modules/home-manager/desktop/hyprland/config/waybar/config`, `modules/home-manager/desktop/hyprland/config/waybar/style.css`, `modules/home-manager/desktop/hyprland/packages.nix`, `modules/home-manager/desktop/hyprland/default.nix`. All station-specific behavior lives in `omo-helpers.nix` and activates ONLY when `omo-helpers.enable = true`.
- No per-script sub-options. One flat `omo-helpers.enable` flag.
- No favicon/icon download in `omo-webapp-install` v1. Use Zen's default icon path (or fall back to a generic web-app icon).
- No hardcoded pixel dimensions in `omo-window-pop`. Percentage of queried monitor resolution only.
- No `imagemagick`, `curl`, `python3` in script runtime deps (v1). Allowed: `hyprctl`, `jq`, `wl-copy`, `wl-paste`, `notify-send`, `rofi`, `wtype`, `cliphist`, `hyprpicker`, `procps`, `systemd`.
- No touching shared hyprland modules (`keybindings.nix`, `default.nix`, `packages.nix`, `services.nix`, `monitors.nix`, `hyprpanel.nix`).
- Animations `source =` line is added via `omo-helpers.nix`'s own `extraConfig = lib.mkAfter` (home-manager merges both modules' extraConfig). No edits to shared `default.nix`.
- No runtime `hostname`-based branching inside scripts. Host-specific behavior lives in Nix, not bash.
- No shared helper libraries across scripts. 2-3 lines of duplication is OK; abstraction is not.
- No `omo-*` script exceeds 30 lines. No `--help`, no `--version`, no color output.
- No changes to Stylix config.
- No changes to Hyprland settings beyond the animations-source extraConfig line.
- No addition of waybar modules beyond `custom/power`.
- No confirmation dialogs in power menu (exactly 5 entries: Lock, Logout, Suspend, Reboot, Shutdown).
- No host-aware script logic — disabled actions (Lock/Suspend on station) simply run `systemctl ...` which fails gracefully; we do not filter menu entries.
- No `extraConfig` beyond the single source line. No config reordering.
- No migration logic or breaking-change handlers.
- No PRs / upstream changes to zen-browser-flake.
- No changes to laptop/VNPC-21 host configs.

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO unit test harness for NixOS modules in this flake
- **Automated tests**: NO unit tests
- **Framework**: N/A — use `nix eval` + runtime verification via `hyprctl` + tmux/SSH to station
- **Strategy**: Each task has (a) build-eval on affected hosts, (b) runtime QA scenarios executed on station via `interactive_bash` tmux SSH sessions or direct local run.

### QA Policy
Every task includes agent-executed QA scenarios using:
- **Bash (local)**: `nix eval`, `jq`, `git diff`, file existence checks. Run directly on the build machine.
- **Bash via SSH**: `ssh station '<command>' | tee .sisyphus/evidence/<file>` — all station-side verification is done via one-shot SSH commands that pipe stdout back to local evidence files. This is the CANONICAL evidence-capture pattern.
- **interactive_bash (tmux)**: ONLY for commands that need a persistent Hyprland session (e.g., launching GUI apps, observing window state via `hyprctl`). For tmux-based scenarios, the evidence capture method is: (1) run the command in tmux, (2) capture output via `tmux capture-pane -p -t <session> | tee .sisyphus/evidence/<file>`, or (3) run the verification command via a separate `ssh station '...' | tee ...` call after the tmux action completes.
- Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

**IMPORTANT — QA Evidence Capture Convention**: Individual scenario steps below use pseudocode for brevity (e.g., `tmux send "ssh station '...'" > file`). The executing agent MUST translate these into the canonical patterns above. Specifically:
- `tmux send "ssh station '<cmd>'" > local-file` → means: run `ssh station '<cmd>' | tee local-file` via Bash, OR run in tmux then `tmux capture-pane`.
- All `.sisyphus/evidence/` files must contain actual command output, not empty placeholders.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Validation + Scaffolding — kick off immediately):
├── T1:  Validate Zen --name/--app flags + capture Zen/Thunar window classes [quick]
├── T2:  Create empty omo-helpers.nix skeleton + wire imports + enable on station [quick]
├── T3:  Add hyprpicker + rofi-emoji + wtype + cliphist + procps to module home.packages [quick]
└── T4:  Configure services.cliphist (user service) [quick]

Wave 2 (Individual scripts — MAX PARALLEL, depend only on T2):
├── T5:  omo-launch-or-focus script [quick]
├── T6:  omo-webapp-install script (uses T1 findings) [quick]
├── T7:  omo-window-pop script [quick]
├── T8:  omo-clipboard-pick script [quick]
├── T9:  omo-emoji-pick script [quick]
└── T10: omo-power-menu script [quick]

Wave 3 (Integration — depends on Wave 1 + 2):
├── T11: Additive keybinds + swap Super+W / Super+E binds (atomic in one file change) [quick]
├── T12: Animation toggle — template file + state file activation + source line + omo-toggle-animations [unspecified-high]
├── T13: Waybar power module — JSON + CSS + reset activation [unspecified-high]

Wave 4 (Cross-host eval — depends on all prior):
└── T14: Cross-host eval regression check (laptop + vnpc-21) [quick]

Wave FINAL (4 parallel reviews — ALL must APPROVE):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real manual QA on station (unspecified-high)
└── F4: Scope fidelity check (deep)
-> Present results -> Get explicit user OK

Critical Path: T1 → T2 → T6 → T11 → T13 → T14 → F1-F4 → user OK
Parallel Speedup: ~60% faster than sequential (Wave 2 runs 6 scripts in parallel)
Max Concurrent: 6 (Wave 2)
```

### Dependency Matrix

- **T1**: — blocks T6
- **T2**: — blocks T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13
- **T3**: T2 — blocks T5, T6, T7, T8, T9, T10, T11, T12, T13
- **T4**: T2, T3 — blocks T8, F3
- **T5**: T2, T3 — blocks T11
- **T6**: T1, T2, T3 — blocks F3
- **T7**: T2, T3 — blocks T11
- **T8**: T2, T3, T4 — blocks T11
- **T9**: T2, T3 — blocks T11
- **T10**: T2, T3 — blocks T11, T13
- **T11**: T2, T3, T5, T7, T8, T9, T10 — blocks T14, F1-F4
- **T12**: T2, T3 — blocks T14, F1-F4
- **T13**: T2, T3, T10 — blocks T14, F1-F4
- **T14**: T11, T12, T13 — blocks F1-F4
- **F1-F4**: T14 — blocks user OK

### Agent Dispatch Summary

- **Wave 1 (4 tasks)**: T1 → `quick`, T2 → `quick`, T3 → `quick`, T4 → `quick`
- **Wave 2 (6 tasks)**: T5-T10 → `quick` each
- **Wave 3 (3 tasks)**: T11 → `quick`, T12 → `unspecified-high`, T13 → `unspecified-high`
- **Wave 4 (1 task)**: T14 → `quick`
- **Wave FINAL (4 tasks)**: F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Validate Zen `--name`/`--app` flags + capture Zen/Thunar Hyprland window classes

  **What to do**:
  - On station, with Zen (`zen-beta`) running, capture `hyprctl clients -j | jq '.[] | {class, title, initialClass, app_id}'` and save to `.sisyphus/evidence/task-1-zen-thunar-classes.json`
  - Same with Thunar running. Record the exact `class` strings.
  - Launch `zen-beta --name TestPWA --new-window https://example.com &`, wait 2s, capture `hyprctl clients -j` again. Check if any window's `class` or `initialClass` == `"TestPWA"`.
  - Also try `zen-beta --app=https://example.com` and observe behavior.
  - Record findings in `.sisyphus/evidence/task-1-zen-flags.md` as a decision memo: one of (a) `--name` sets class → use it; (b) `--app=` works → use it; (c) neither works → fall back to plain `zen-beta URL` + a custom `.desktop` entry (StartupWMClass is cosmetic only in this case).

  **Must NOT do**:
  - Modify any nix files in this task. Validation only.
  - Skip this — T6 depends on the outcome.

  **Recommended Agent Profile**:
  - **Category**: `quick` — Runtime probing via tmux + `hyprctl`; no code generation.
  - **Skills**: none
  - **Skills Evaluated but Omitted**:
    - `dev-browser`: not needed — we're inspecting Hyprland state, not browser internals

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T2, T3, T4)
  - **Blocks**: T6
  - **Blocked By**: None

  **References**:
  - `modules/home-manager/misc/zen-browser.nix:21-23` — how Zen is installed from flake input
  - `modules/home-manager/misc/zen-browser.nix:39-60` — existing `.desktop` entry (template for T6)
  - `flake.nix:11-14` — Zen flake input source
  - `hosts/station/default.nix` — host identity for SSH target
  - WHY: T6 (`omo-webapp-install`) must know which flag actually sets the Hyprland window class; wrong choice = non-functional webapp installer.

  **Acceptance Criteria**:
  - [ ] `.sisyphus/evidence/task-1-zen-thunar-classes.json` exists, contains valid JSON
  - [ ] `.sisyphus/evidence/task-1-zen-flags.md` exists, documents one definitive outcome: use `--name`, use `--app=`, or fall back to `.desktop` StartupWMClass
  - [ ] Exact Zen window class string recorded (e.g. `"zen-beta"`, `"zen"`, `"Navigator"`)
  - [ ] Exact Thunar window class string recorded

  **QA Scenarios**:

  ```
  Scenario: Capture Zen + Thunar window classes
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: Zen and Thunar installed; user logged into Hyprland session.
    Steps:
      1. tmux send "ssh station" — SSH into station.
      2. tmux send "zen-beta &" — ensure Zen is running.
      3. tmux send "thunar &" — ensure Thunar is running; wait 2s.
      4. Run: hyprctl clients -j | jq '[.[] | {class, title, initialClass}]' > /tmp/classes.json
      5. scp /tmp/classes.json local:.sisyphus/evidence/task-1-zen-thunar-classes.json
    Expected Result: JSON contains objects for Zen (class matching zen/zen-beta/Navigator) and Thunar (class matching thunar/Thunar).
    Failure Indicators: JSON empty, or no class strings captured.
    Evidence: .sisyphus/evidence/task-1-zen-thunar-classes.json

  Scenario: Test Zen `--name` flag
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: Zen installed on station.
    Steps:
      1. tmux send "zen-beta --name TestPWA --new-window https://example.com &"
      2. Wait 3 seconds.
      3. Run: hyprctl clients -j | jq '.[] | select(.title | contains("Example")) | {class, initialClass}'
      4. Inspect output.
    Expected Result: At least one window's `class` OR `initialClass` contains "TestPWA" (flag works) OR matches default Zen class (flag ignored).
    Failure Indicators: No matching window found — Zen refused to launch with that URL.
    Evidence: .sisyphus/evidence/task-1-zen-flags.md (includes captured JSON snippet + decision)
  ```

  **Commit**: NO (validation-only task; evidence files are not part of the repo)

- [x] 2. Scaffold `omo-helpers.nix` skeleton + wire imports + enable on station

  **What to do**:
  - Create `modules/home-manager/desktop/omo-helpers.nix` with:
    ```nix
    { lib, config, pkgs, ... }:
    let cfg = config.omo-helpers; in
    {
      options.omo-helpers.enable = lib.mkEnableOption "Omarchy-style desktop UX helpers (station testbed)";
      config = lib.mkIf cfg.enable {
        home-manager.users.${config.user} = { /* intentionally empty — populated in T3+ */ };
      };
    }
    ```
  - Update the home-manager imports chain so the new module is loaded. Confirm via `modules/home-manager/default.nix` or `modules/home-manager/desktop/default.nix` whichever currently aggregates desktop modules (explore output showed desktop imports `./hyprland` — add `./omo-helpers.nix` as a sibling). Keep it imported on all desktops so `nix eval` stays green; enabling is opt-in via the flag.
  - In `hosts/station/default.nix`, add `omo-helpers.enable = true;` (in the appropriate `config = { ... }` block).

  **Must NOT do**:
  - Add any actual functionality (packages, scripts, activation) — skeleton only.
  - Enable on laptop or vnpc-21.
  - Rename, reorder, or reformat existing imports.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T3, T4)
  - **Blocks**: T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13
  - **Blocked By**: None

  **References**:
  - `modules/home-manager/app/discord.nix` — WHY: exact template for `cfg`-binding + `options.<name>.enable` + `config = lib.mkIf cfg.enable { home-manager.users.${config.user} = { ... }; };` pattern
  - `CLAUDE.md:"Module Patterns"` — WHY: mandatory `let cfg = config.<name>;` binding; `lib.mkIf cfg.enable` guard; home-manager module nested under `home-manager.users.${config.user}`
  - `modules/home-manager/desktop/hyprland/default.nix` — current desktop module to imitate for location
  - `hosts/station/default.nix` — target enable site; find the `config = { ... }` block that already enables other modules (e.g. `hyprland.enable`)

  **Acceptance Criteria**:
  - [ ] File `modules/home-manager/desktop/omo-helpers.nix` exists
  - [ ] File contains `options.omo-helpers.enable = lib.mkEnableOption ...` and `let cfg = config.omo-helpers;`
  - [ ] `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` → store path
  - [ ] `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` → store path
  - [ ] `nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath'` → store path (note: flake attr is uppercase `VNPC-21` per `parts/hosts.nix:37`)
  - [ ] `grep -c "omo-helpers.enable = true" hosts/station/default.nix` → 1
  - [ ] `grep -c "omo-helpers" hosts/laptop/default.nix hosts/vnpc-21/default.nix` → 0 (not enabled on other hosts)

  **QA Scenarios**:

  ```
  Scenario: Build-eval succeeds across all desktop hosts
    Tool: Bash
    Preconditions: skeleton module written, imports wired, station enable added.
    Steps:
      1. nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1 | tee .sisyphus/evidence/task-2-eval-station.log
      2. nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath 2>&1 | tee .sisyphus/evidence/task-2-eval-laptop.log
      3. nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath' 2>&1 | tee .sisyphus/evidence/task-2-eval-vnpc21.log
    Expected Result: All three commands output a `/nix/store/...drv` path and exit 0.
    Failure Indicators: "error:", "cannot coerce", "undefined variable", non-zero exit.
    Evidence: .sisyphus/evidence/task-2-eval-{station,laptop,vnpc21}.log

  Scenario: Flag is opt-in (not enabled on other hosts)
    Tool: Bash
    Preconditions: station default.nix edited with flag.
    Steps:
      1. nix eval .#nixosConfigurations.station.config.omo-helpers.enable
      2. nix eval .#nixosConfigurations.laptop.config.omo-helpers.enable
      3. nix eval '.#nixosConfigurations."VNPC-21".config.omo-helpers.enable'
    Expected Result: station = "true", laptop = "false", VNPC-21 = "false".
    Failure Indicators: attribute missing error, or laptop/VNPC-21 returning "true".
    Evidence: .sisyphus/evidence/task-2-flag-state.log
  ```

  **Commit**: YES
  - Message: `feat(station): scaffold omo-helpers module`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`, `hosts/station/default.nix`, (import-site file as determined)
  - Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath && nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath'`

- [x] 3. Add desktop-UX packages to `omo-helpers.nix`

  **What to do**:
  - Inside the `home-manager.users.${config.user}` block of `omo-helpers.nix`, add a `home.packages` list containing: `pkgs.hyprpicker`, `pkgs.rofi-emoji`, `pkgs.wtype`, `pkgs.cliphist`, `pkgs.wl-clipboard`, `pkgs.libnotify`, `pkgs.procps`, `pkgs.jq`.
  - `wl-clipboard` may already be present via the hyprland module — NixOS deduplicates, so it's safe to re-list. If a `nix-build` warning fires, resolve by omitting.
  - Use `pkgs` (stable) for every package to match existing hyprland module conventions.

  **Must NOT do**:
  - Add any packages not in this list (no imagemagick, no curl, no xdotool, no slurp duplicates).
  - Use `pkgs-unstable` unless a stable-channel build fails (which shouldn't happen for these packages).
  - Touch any other config block yet.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO (serializes on omo-helpers.nix with T4-T12)
  - **Parallel Group**: Wave 1 — but sequenced after T2 and before T4-T12 editing same file
  - **Blocks**: T4, T5, T6, T7, T8, T9, T10, T11, T12, T13
  - **Blocked By**: T2

  **References**:
  - `modules/home-manager/desktop/hyprland/packages.nix:60-80` — existing `home.packages` block in the adjacent module; imitate style + comment conventions
  - `modules/home-manager/desktop/hyprland/packages.nix:69` — confirms `pkgs.rofi` is the X11 variant → use `pkgs.rofi-emoji` (NOT `rofi-emoji-wayland`) to match ABI. WHY: wrong variant = plugin load failure.
  - WHY each package: `hyprpicker` (color picker, T5 wraps it indirectly via hyprctl), `rofi-emoji` (T9 emoji picker), `wtype` (types emoji into focused Wayland window; `rofi-emoji` insert-mode requires it), `cliphist` (T4+T8 clipboard history), `wl-clipboard` (wl-copy/wl-paste CLI binaries used by scripts), `libnotify` (notify-send for errors), `procps` (pkill for kill-then-open rofi pattern), `jq` (JSON parsing in scripts)

  **Acceptance Criteria**:
  - [ ] `omo-helpers.nix` contains `home.packages = with pkgs; [ ... ]` with all 8 packages
  - [ ] `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` → store path
  - [ ] After `just rebuild` on station: `for p in hyprpicker rofi wtype cliphist wl-copy notify-send pkill jq; do command -v $p >/dev/null && echo "OK: $p" || echo "MISSING: $p"; done` → all OK
  - [ ] `nix eval` still succeeds on laptop + vnpc-21 (regression check; packages only land when flag is true)

  **QA Scenarios**:

  ```
  Scenario: All packages become available on station after rebuild
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T2 merged; omo-helpers.enable = true on station; T3 packages added.
    Steps:
      1. tmux send "ssh station 'just rebuild' 2>&1 | tail -20"
      2. tmux send "ssh station 'for p in hyprpicker rofi wtype cliphist wl-copy notify-send pkill jq; do command -v \$p && echo OK \$p || echo MISS \$p; done'" > .sisyphus/evidence/task-3-binaries.log
    Expected Result: Rebuild succeeds; all 8 binaries print an absolute path + "OK <name>".
    Failure Indicators: "MISS" for any binary; rebuild error.
    Evidence: .sisyphus/evidence/task-3-binaries.log

  Scenario: Packages NOT installed on laptop (regression)
    Tool: Bash
    Preconditions: T3 complete, laptop not rebuilt yet.
    Steps:
      1. nix eval .#nixosConfigurations.laptop.config.home-manager.users.none.home.packages --apply 'ps: map (p: p.pname or p.name) ps' 2>&1 | tee .sisyphus/evidence/task-3-laptop-packages.log
      2. grep -c "hyprpicker\|rofi-emoji\|cliphist" .sisyphus/evidence/task-3-laptop-packages.log
    Expected Result: Count = 0 — none of the omo-helpers packages land on laptop.
    Failure Indicators: Count > 0 (module leaking to non-enabled hosts).
    Evidence: .sisyphus/evidence/task-3-laptop-packages.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add desktop-UX packages`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station + laptop + vnpc-21

- [x] 4. Enable `services.cliphist` user service

  **What to do**:
  - Inside `home-manager.users.${config.user}` in `omo-helpers.nix`, add:
    ```nix
    services.cliphist = {
      enable = true;
      allowImages = false;
      extraOptions = [ "-max-items" "500" ];
    };
    ```
  - `allowImages = false` prevents bloat from screenshot clipboard captures.
  - `-max-items 500` caps history to 500 entries (enough for daily use, prevents unbounded DB growth).

  **Must NOT do**:
  - Add image support (conflicts with screenshot workflow that already writes images to ~/Pictures).
  - Write a hand-rolled systemd unit. Use the home-manager module.
  - Tune other options (`systemdTarget`, alternate DB path) — defaults are correct.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO (edits same file as T3, T5-T12)
  - **Parallel Group**: Wave 1 (sequenced after T3)
  - **Blocks**: T8, F3
  - **Blocked By**: T2, T3

  **References**:
  - `home-manager` module `services.cliphist` — WHY: canonical way to run cliphist watcher as a systemd user service tied to `graphical-session.target`, avoids race conditions with Wayland socket availability
  - Metis finding section 6: cliphist interacts fine with `wl-clip-persist`; minor duplicate-entry risk on session resume (acceptable)
  - `modules/home-manager/desktop/hyprland/packages.nix` — existing wl-clip-persist reference (to confirm coexistence)

  **Acceptance Criteria**:
  - [ ] `omo-helpers.nix` contains `services.cliphist.enable = true;`
  - [ ] `nix eval` succeeds on station
  - [ ] After rebuild: `systemctl --user is-active cliphist` → `active`
  - [ ] After `echo "test-$(date +%s)" | wl-copy && sleep 0.5 && cliphist list | head -1` → output contains the test string

  **QA Scenarios**:

  ```
  Scenario: cliphist service starts and records clipboard
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T4 merged, station rebuilt.
    Steps:
      1. tmux send "ssh station 'systemctl --user is-active cliphist'" > .sisyphus/evidence/task-4-service.log
      2. tmux send "ssh station 'TESTVAL=test-cliphist-$(date +%s); echo \$TESTVAL | wl-copy; sleep 1; cliphist list | head -3'" > .sisyphus/evidence/task-4-recording.log
    Expected Result: service.log = "active"; recording.log first line contains "test-cliphist-<digits>".
    Failure Indicators: "inactive" / "failed"; recording.log empty or missing test string.
    Evidence: .sisyphus/evidence/task-4-service.log, .sisyphus/evidence/task-4-recording.log

  Scenario: Images NOT recorded (allowImages = false)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T4 merged, cliphist running.
    Steps:
      1. tmux send "ssh station 'wl-copy -t image/png < ~/Pictures/screenshots/*.png 2>/dev/null | head -1 || true; sleep 1; cliphist list | head -5'" > .sisyphus/evidence/task-4-no-images.log
    Expected Result: `cliphist list` output contains no binary garbage (no image entries).
    Failure Indicators: list contains binary blobs or very long base64-like strings.
    Evidence: .sisyphus/evidence/task-4-no-images.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): enable cliphist user service`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station

- [ ] 5. Add `omo-launch-or-focus` script

  **What to do**:
  - Inside `home-manager.users.${config.user}.home.packages` in `omo-helpers.nix`, append `(pkgs.writeShellScriptBin "omo-launch-or-focus" ''...'')`.
  - Script (≤30 lines):
    ```bash
    #!/usr/bin/env bash
    # Usage: omo-launch-or-focus <class-regex> <launch-command...>
    set -eu
    CLASS_RE="$1"; shift
    ADDR=$(${pkgs.hyprland}/bin/hyprctl clients -j | \
      ${pkgs.jq}/bin/jq -r --arg re "$CLASS_RE" \
        '[.[] | select((.class // "") | test($re; "i"))] | .[0].address // empty')
    if [ -n "$ADDR" ]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$ADDR"
    else
      exec "$@"
    fi
    ```
  - Takes a class regex + a command. Focuses first matching window if present; otherwise launches the command.
  - Use Nix interpolation for `hyprctl` and `jq` to avoid PATH dependency.

  **Must NOT do**:
  - Add sub-options like a preconfigured class list.
  - Add logging, debug flags, or help text.
  - Depend on runtime `hostname` check.
  - Handle the case of multiple matching windows specially — always focus the first one.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO (edits same file)
  - **Parallel Group**: Wave 2 (within-file sequence)
  - **Blocks**: T11
  - **Blocked By**: T2, T3

  **References**:
  - `nixpkgs` docs — `writeShellScriptBin`: generates a script derivation exposing `bin/<name>`
  - Metis MUST directive: use `${pkgs.X}/bin/Y` interpolation for runtime deps
  - T1 output — `zen-beta` and `thunar` window class strings; T11 uses them as arguments to this script

  **Acceptance Criteria**:
  - [ ] Script contains exactly 2 Nix interpolations (`${pkgs.hyprland}/bin/hyprctl`, `${pkgs.jq}/bin/jq`)
  - [ ] Script length ≤ 30 lines including shebang and comments
  - [ ] After rebuild on station: `command -v omo-launch-or-focus` → absolute path
  - [ ] `omo-launch-or-focus "thunar" thunar` with no Thunar open → launches Thunar; with Thunar open → focuses existing window

  **QA Scenarios**:

  ```
  Scenario: No matching window → launch
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: No Thunar windows open (verify via `hyprctl clients -j | jq '.[] | select(.class | test("thunar";"i"))'` returns empty).
    Steps:
      1. tmux send "ssh station 'hyprctl clients -j | jq \"[.[] | select((.class // \\\"\\\") | test(\\\"thunar\\\";\\\"i\\\"))] | length\"'" > /tmp/before.txt
      2. tmux send "ssh station 'omo-launch-or-focus thunar thunar &'" — launch
      3. Wait 2 seconds.
      4. tmux send "ssh station 'hyprctl clients -j | jq \"[.[] | select((.class // \\\"\\\") | test(\\\"thunar\\\";\\\"i\\\"))] | length\"'" > /tmp/after.txt
      5. Save both to .sisyphus/evidence/task-5-launch.log
    Expected Result: before = 0, after = 1.
    Failure Indicators: after = 0 (launch failed) or after > 1 (spawned duplicate).
    Evidence: .sisyphus/evidence/task-5-launch.log

  Scenario: Existing matching window → focus, no duplicate
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: exactly 1 Thunar window open.
    Steps:
      1. tmux send "ssh station 'omo-launch-or-focus thunar thunar'"
      2. Wait 1 second.
      3. tmux send "ssh station 'hyprctl clients -j | jq \"[.[] | select((.class // \\\"\\\") | test(\\\"thunar\\\";\\\"i\\\"))] | length\"'" > .sisyphus/evidence/task-5-focus.log
      4. tmux send "ssh station 'hyprctl activewindow -j | jq -r .class'" >> .sisyphus/evidence/task-5-focus.log
    Expected Result: Count remains 1; activewindow class matches thunar regex.
    Failure Indicators: Count = 2 (spawned new); activewindow class does NOT match.
    Evidence: .sisyphus/evidence/task-5-focus.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add omo-launch-or-focus script`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station

- [ ] 6. Add `omo-webapp-install` script

  **What to do**:
  - Append to `home.packages` in `omo-helpers.nix`:
    ```nix
    (pkgs.writeShellScriptBin "omo-webapp-install" ''
      #!/usr/bin/env bash
      set -eu
      NAME="${1:?usage: omo-webapp-install <Name> <URL>}"
      URL="${2:?usage: omo-webapp-install <Name> <URL>}"
      APPDIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
      mkdir -p "$APPDIR"
      FILE="$APPDIR/omo-webapp-$(echo "$NAME" | tr ' ' '-').desktop"
      cat > "$FILE" <<EOF
      [Desktop Entry]
      Type=Application
      Name=$NAME
      Exec=${T1_EXEC_TEMPLATE}
      Icon=zen-beta
      Categories=Network;WebBrowser;
      StartupWMClass=$NAME
      NoDisplay=false
      EOF
      ${pkgs.desktop-file-utils}/bin/desktop-file-validate "$FILE"
      ${pkgs.libnotify}/bin/notify-send "Web App Installed" "$NAME → $URL" -t 3000
    '')
    ```
  - Replace `${T1_EXEC_TEMPLATE}` at implementation time based on T1 evidence:
    - If T1 confirms `--name` works: `Exec=zen-beta --name "$NAME" --new-window "$URL"`
    - Else if T1 confirms `--app=`: `Exec=zen-beta --app="$URL"`
    - Else (fallback): `Exec=zen-beta --new-window "$URL"` (StartupWMClass still set; Hyprland window rules can target it by title if needed later)
  - Add `pkgs.desktop-file-utils` to the `home.packages` list above the script.

  **Must NOT do**:
  - Download favicons. Use `Icon=zen-beta` as a universal default; user can manually edit the .desktop file to swap.
  - Support additional flags (`--profile`, `--private`, custom user-agent).
  - Use `pkgs.chromium` / `pkgs.firefox` fallback; Zen only.
  - Exceed 30 lines of actual shell (comments don't count).

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO (edits same file)
  - **Parallel Group**: Wave 2
  - **Blocks**: F3
  - **Blocked By**: T1, T2, T3

  **References**:
  - T1 evidence `.sisyphus/evidence/task-1-zen-flags.md` — source of the `Exec=` template decision
  - `modules/home-manager/misc/zen-browser.nix:39-60` — existing .desktop structure to mirror
  - XDG Desktop Entry Specification — WHY StartupWMClass: lets Hyprland match PWA windows distinctly even when `--name` is cosmetic-only
  - `pkgs.desktop-file-utils` (nixpkgs) — provides `desktop-file-validate` for sanity-check

  **Acceptance Criteria**:
  - [ ] Script exists; `command -v omo-webapp-install` → path
  - [ ] `omo-webapp-install "TestApp" "https://example.com"` exits 0
  - [ ] `~/.local/share/applications/omo-webapp-TestApp.desktop` exists
  - [ ] `desktop-file-validate <path>` exits 0 (zero warnings acceptable)
  - [ ] Launching from desktop entry opens Zen pointing at the URL
  - [ ] No favicon/curl/imagemagick in script (grep for forbidden tokens)

  **QA Scenarios**:

  ```
  Scenario: Install a test webapp → desktop file created and valid
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T6 merged, station rebuilt.
    Steps:
      1. tmux send "ssh station 'rm -f ~/.local/share/applications/omo-webapp-TestApp.desktop; omo-webapp-install TestApp https://example.com; cat ~/.local/share/applications/omo-webapp-TestApp.desktop'" > .sisyphus/evidence/task-6-desktop-file.txt
      2. tmux send "ssh station 'desktop-file-validate ~/.local/share/applications/omo-webapp-TestApp.desktop && echo VALID || echo INVALID'" >> .sisyphus/evidence/task-6-desktop-file.txt
    Expected Result: File content contains `Name=TestApp`, `Exec=zen-beta ...`, `StartupWMClass=TestApp`; validation prints "VALID".
    Failure Indicators: File missing, invalid Desktop Entry, validation errors.
    Evidence: .sisyphus/evidence/task-6-desktop-file.txt

  Scenario: Missing args → error + exit non-zero (failure path)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: script installed.
    Steps:
      1. tmux send "ssh station 'omo-webapp-install; echo EXIT=$?'" > .sisyphus/evidence/task-6-missing-args.log
    Expected Result: Output contains "usage:" message; `EXIT=` value is non-zero.
    Failure Indicators: EXIT=0 (silently succeeded without required args); script crashes with bash-internal error instead of helpful message.
    Evidence: .sisyphus/evidence/task-6-missing-args.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add omo-webapp-install script`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station

- [ ] 7. Add `omo-window-pop` script

  **What to do**:
  - Append script to `home.packages`:
    ```bash
    #!/usr/bin/env bash
    set -eu
    HYPRCTL=${pkgs.hyprland}/bin/hyprctl
    JQ=${pkgs.jq}/bin/jq
    ACT=$($HYPRCTL activewindow -j)
    FLOATING=$(echo "$ACT" | $JQ -r '.floating')
    PINNED=$(echo "$ACT" | $JQ -r '.pinned')
    FULLSCREEN=$(echo "$ACT" | $JQ -r '.fullscreen')
    MONITOR=$(echo "$ACT" | $JQ -r '.monitor')
    RES=$($HYPRCTL monitors -j | $JQ -r --arg m "$MONITOR" '.[] | select(.id == ($m | tonumber)) | "\(.width)x\(.height)"')
    W=$(echo "$RES" | cut -dx -f1)
    H=$(echo "$RES" | cut -dx -f2)
    TW=$((W * 75 / 100))
    TH=$((H * 75 / 100))
    if [ "$FULLSCREEN" != "0" ] && [ "$FULLSCREEN" != "null" ]; then
      $HYPRCTL dispatch fullscreen 0
    fi
    if [ "$FLOATING" = "true" ] && [ "$PINNED" = "true" ]; then
      $HYPRCTL dispatch pin
      $HYPRCTL dispatch togglefloating
      exit 0
    fi
    [ "$FLOATING" = "false" ] && $HYPRCTL dispatch togglefloating
    $HYPRCTL dispatch resizeactive exact "$TW" "$TH"
    $HYPRCTL dispatch centerwindow
    [ "$PINNED" = "false" ] && $HYPRCTL dispatch pin || true
    ```
  - Detects floating/pinned/fullscreen state and branches. Toggle behavior: tiled→popped, popped→tiled.
  - Uses 75% of the active monitor's native resolution (queried via `hyprctl monitors -j`).

  **Must NOT do**:
  - Hardcode pixel dimensions.
  - Use `hyprctl monitors` without filtering to the active monitor.
  - Skip fullscreen-handling branch (togglefloating on fullscreen window breaks layouts).
  - Ignore the case where `monitor` field is numeric vs string; use tonumber in jq.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2
  - **Blocks**: T11
  - **Blocked By**: T2, T3

  **References**:
  - `hosts/station/default.nix:210-212` — dual monitor geometry; WHY percentage sizing matters (portrait + landscape at vastly different resolutions)
  - Hyprland `hyprctl dispatch` ref: `togglefloating`, `resizeactive exact W H`, `centerwindow`, `pin`, `fullscreen 0` — canonical dispatch names
  - Metis section 6 (edge cases): tiled / floating / pinned / fullscreen branches

  **Acceptance Criteria**:
  - [ ] Script ≤ 30 lines of shell
  - [ ] `command -v omo-window-pop` → path
  - [ ] When run on a tiled window: window becomes floating, centered, pinned, ~75% of monitor size
  - [ ] When run a second time on the same window: window returns to tiled state (unpin + unfloat)
  - [ ] When run on a fullscreen window: fullscreen is cleared first, then window is popped

  **QA Scenarios**:

  ```
  Scenario: Tiled window → popped
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: one tiled window focused.
    Steps:
      1. tmux send "ssh station 'hyprctl activewindow -j | jq \"{floating, pinned, size}\" > /tmp/before.json'"
      2. tmux send "ssh station 'omo-window-pop'"
      3. Wait 0.5s.
      4. tmux send "ssh station 'hyprctl activewindow -j | jq \"{floating, pinned, size}\" > /tmp/after.json && cat /tmp/after.json'" > .sisyphus/evidence/task-7-pop.log
    Expected Result: after shows `floating: true, pinned: true`; size is ~75% of monitor (check via hyprctl monitors — within ±5px).
    Failure Indicators: floating still false, or pinned still false, or size unchanged.
    Evidence: .sisyphus/evidence/task-7-pop.log

  Scenario: Popped window → returned to tiled (reverse toggle)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: a popped (floating + pinned) window is focused.
    Steps:
      1. tmux send "ssh station 'omo-window-pop'"
      2. Wait 0.5s.
      3. tmux send "ssh station 'hyprctl activewindow -j | jq \"{floating, pinned}\"'" > .sisyphus/evidence/task-7-unpop.log
    Expected Result: `floating: false, pinned: false`.
    Failure Indicators: still floating or still pinned.
    Evidence: .sisyphus/evidence/task-7-unpop.log

  Scenario: Fullscreen window → exits fullscreen first, then pops
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: fullscreen window focused.
    Steps:
      1. tmux send "ssh station 'hyprctl dispatch fullscreen 1'"
      2. tmux send "ssh station 'omo-window-pop'"
      3. Wait 0.5s.
      4. tmux send "ssh station 'hyprctl activewindow -j | jq \"{fullscreen, floating, pinned}\"'" > .sisyphus/evidence/task-7-fullscreen.log
    Expected Result: `fullscreen: 0, floating: true, pinned: true`.
    Failure Indicators: fullscreen != 0, or pop did not complete.
    Evidence: .sisyphus/evidence/task-7-fullscreen.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add omo-window-pop script`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station

- [ ] 8. Add `omo-clipboard-pick` script

  **What to do**:
  - Append script:
    ```bash
    #!/usr/bin/env bash
    set -eu
    ${pkgs.procps}/bin/pkill -x rofi || true
    PICK=$(${pkgs.cliphist}/bin/cliphist list | \
      ${pkgs.rofi}/bin/rofi -dmenu -p "Clipboard" -theme-str 'window { width: 50%; }')
    [ -n "$PICK" ] && echo "$PICK" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
    ```
  - Kill-then-open rofi pattern (NOT the launcher's toggle). Feeds cliphist history through rofi dmenu, decodes selection, pipes to wl-copy.
  - Inline `-theme-str` widens the dmenu just enough for clipboard text previews without creating a new `.rasi` file.

  **Must NOT do**:
  - Create a `.rasi` theme file for the clipboard picker.
  - Use the launcher's `pgrep rofi && killall rofi || ...` toggle pattern (breaks when launcher is already open).
  - Add filtering / deletion / pinning features.
  - Sanitize output (cliphist decode handles binary-safety).

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2
  - **Blocks**: T11
  - **Blocked By**: T2, T3, T4

  **References**:
  - `modules/home-manager/desktop/hyprland/keybindings.nix:44` — launcher's toggle pattern to AVOID (that pattern is fine for a single-modi launcher; not for multi-picker UX)
  - Metis finding Q6 — "kill-then-open" rationale: multiple rofi callers must not interfere with each other
  - `services.cliphist` home-manager docs — `cliphist list` + `cliphist decode` as the canonical pipeline

  **Acceptance Criteria**:
  - [ ] Script ≤ 30 lines
  - [ ] `command -v omo-clipboard-pick` → path
  - [ ] Copying three test strings with `wl-copy`, then invoking the picker (simulated via rofi's `-dump` flag for testability), shows all three in the list
  - [ ] Selecting an item re-copies it to clipboard (verified via `wl-paste`)

  **QA Scenarios**:

  ```
  Scenario: Picker lists previously-copied strings
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: cliphist active, DB empty or cleared.
    Steps:
      1. tmux send "ssh station 'cliphist wipe; for s in alpha-$(date +%s) beta-$(date +%s) gamma-$(date +%s); do echo \$s | wl-copy; sleep 0.3; done; cliphist list | head -10'" > .sisyphus/evidence/task-8-list.log
    Expected Result: Output contains three distinct test strings (alpha-, beta-, gamma- prefixed).
    Failure Indicators: List empty, or fewer than 3 entries (indicates cliphist watcher not running).
    Evidence: .sisyphus/evidence/task-8-list.log

  Scenario: Selecting an item restores it to clipboard
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: cliphist DB has >=1 entry; rofi installed; wl-paste available.
    Steps:
      1. tmux send "ssh station 'echo initial-$(date +%s) | wl-copy; sleep 0.3; target=marker-$(date +%s); echo \$target | wl-copy; sleep 0.3; echo newer-$(date +%s) | wl-copy; sleep 0.3; ID=\$(cliphist list | grep \$target | head -1); echo \"\$ID\" | cliphist decode | wl-copy; sleep 0.3; wl-paste'" > .sisyphus/evidence/task-8-restore.log
    Expected Result: Final wl-paste output starts with "marker-".
    Failure Indicators: Output = the "newer-" string (cliphist chain broken), or empty.
    Evidence: .sisyphus/evidence/task-8-restore.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add omo-clipboard-pick script`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station

- [ ] 9. Add `omo-emoji-pick` script

  **What to do**:
  - Append script:
    ```bash
    #!/usr/bin/env bash
    set -eu
    ${pkgs.procps}/bin/pkill -x rofi || true
    exec ${pkgs.rofi}/bin/rofi -modi emoji -show emoji -emoji-format "{emoji}"
    ```
  - Uses `rofi-emoji`'s `emoji` modi. `rofi-emoji` auto-copies selected emoji to clipboard; combined with `wl-clipboard` it lands in Wayland clipboard. For insert-into-focused-window, `rofi-emoji` calls `xdotool` by default on X11 — on XWayland-Rofi targeting Wayland-native apps, this FAILS silently.
  - Workaround: copy-only mode is sufficient for v1. User copies emoji, then pastes with Ctrl+V. If insert-mode is desired later, migrate to `rofi-wayland` + `rofi-emoji-wayland` (separate future enhancement).
  - Add `home.file.".config/rofimoji.rc".text = ''action = copy''` ONLY if `rofi-emoji` config is needed. Skip if the default is copy.

  **Must NOT do**:
  - Switch to `rofi-wayland` just for insert-mode support (triggers cascade: rofi-emoji-wayland, theme re-verification, launcher retest).
  - Create a new rofi theme.
  - Add emoji frequency tracking / favorites.
  - Use `wtype` directly in the script — `rofi-emoji`'s built-in insert path would need it, but we're using copy-mode.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2
  - **Blocks**: T11
  - **Blocked By**: T2, T3

  **References**:
  - Metis section 1 Q1 — rofi variant: `pkgs.rofi-emoji` matches `pkgs.rofi` (X11); wayland variant would mismatch ABI
  - Metis section 6 — rofi-emoji on X11 uses xdotool for insert; unreliable on Wayland-native apps; copy-mode sidesteps this

  **Acceptance Criteria**:
  - [ ] Script ≤ 30 lines
  - [ ] `command -v omo-emoji-pick` → path
  - [ ] Running `rofi -modi emoji -show emoji -dump-config 2>&1 | grep -q emoji` → exit 0 (plugin loads)
  - [ ] (Interactive) selecting an emoji via the picker writes it to clipboard — verifiable via `wl-paste`

  **QA Scenarios**:

  ```
  Scenario: rofi-emoji plugin loads successfully
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T3 installed rofi-emoji; station rebuilt.
    Steps:
      1. tmux send "ssh station 'rofi -modi emoji -dump-config 2>&1 | grep -c \"^[[:space:]]*emoji\"'" > .sisyphus/evidence/task-9-plugin.log
    Expected Result: Output >= 1 (plugin symbol present in dump).
    Failure Indicators: 0 or "unknown modi" error.
    Evidence: .sisyphus/evidence/task-9-plugin.log

  Scenario: Kill-then-open works when launcher is already open
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: nothing.
    Steps:
      1. tmux send "ssh station 'rofi -show drun &'" — start launcher
      2. Wait 1s.
      3. tmux send "ssh station 'pgrep -c -x rofi'" > /tmp/before.log — expect >= 1
      4. tmux send "ssh station 'omo-emoji-pick &'" — call picker
      5. Wait 1s.
      6. tmux send "ssh station 'pgrep -x rofi | wc -l'" > .sisyphus/evidence/task-9-kill-then-open.log — expect 1 (old killed, new started)
      7. tmux send "ssh station 'pkill -x rofi'" — clean up.
    Expected Result: before >= 1; after = 1 (exactly one rofi, the emoji picker).
    Failure Indicators: after = 0 (emoji picker died) or after = 2 (old rofi not killed — toggle conflict).
    Evidence: .sisyphus/evidence/task-9-kill-then-open.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add omo-emoji-pick script`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station

- [ ] 10. Add `omo-power-menu` script

  **What to do**:
  - Append script:
    ```bash
    #!/usr/bin/env bash
    set -eu
    ${pkgs.procps}/bin/pkill -x rofi || true
    CHOICE=$(printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | \
      ${pkgs.rofi}/bin/rofi -dmenu -p "Power" -theme-str 'window { width: 20%; }')
    case "$CHOICE" in
      Lock)     ${pkgs.systemd}/bin/loginctl lock-session ;;
      Logout)   ${pkgs.hyprland}/bin/hyprctl dispatch exit ;;
      Suspend)  ${pkgs.systemd}/bin/systemctl suspend ;;
      Reboot)   ${pkgs.systemd}/bin/systemctl reboot ;;
      Shutdown) ${pkgs.systemd}/bin/systemctl poweroff ;;
      *)        exit 0 ;;
    esac
    ```
  - 5 entries, no confirmation, no icons. On station, Lock falls through to `loginctl lock-session` (no locker registered → no-op, graceful) and Suspend fails silently per `AllowSuspend=no`. We do not branch per-host in the script.

  **Must NOT do**:
  - Add confirmation dialog.
  - Add icons, separators, or colored entries.
  - Add hibernate, switch-user, screen-off.
  - Branch on hostname — scripts are host-agnostic.
  - Call `swaylock` directly (not installed on station).

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2
  - **Blocks**: T11, T13
  - **Blocked By**: T2, T3

  **References**:
  - `hosts/station/default.nix:86-91` — `AllowSuspend=no`, `AllowHibernation=no` (WHY: Suspend will fail; graceful failure is acceptable UX)
  - `hosts/station/default.nix:141-142` — swaylock + hypridle force-disabled (WHY: Lock via loginctl is a no-op but doesn't error)
  - Existing Super+Shift+E was UNUSED per T11 verification of `keybindings.nix`

  **Acceptance Criteria**:
  - [ ] Script ≤ 30 lines
  - [ ] `command -v omo-power-menu` → path
  - [ ] `printf "\n" | rofi -dmenu -p Power` mechanic works (test via dmenu dry-run)
  - [ ] On station, invoking with `CHOICE=Lock` simulates `loginctl lock-session` (no error thrown)
  - [ ] Reboot / Shutdown paths exist but are NOT executed during tests

  **QA Scenarios**:

  ```
  Scenario: Menu entries render correctly (list contents)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T10 merged, station rebuilt.
    Steps:
      1. tmux send "ssh station 'printf \"Lock\\nLogout\\nSuspend\\nReboot\\nShutdown\" | rofi -dmenu -dump-xresources-theme 2>/dev/null >/dev/null; echo OK'" > .sisyphus/evidence/task-10-rofi-dmenu.log
      2. Verify the actual entries by running the script non-interactively with a stub selection:
         tmux send "ssh station 'echo Lock | rofi -dmenu -p Power -no-custom < /dev/null | head -1'" (skip if too interactive; alt: just verify script exists)
    Expected Result: "OK" printed; no rofi invocation errors.
    Failure Indicators: rofi crashes, "unknown option" errors.
    Evidence: .sisyphus/evidence/task-10-rofi-dmenu.log

  Scenario: Lock on station (disabled locker) → no-op, no error
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: station has swaylock disabled.
    Steps:
      1. tmux send "ssh station 'loginctl lock-session; echo EXIT=$?'" > .sisyphus/evidence/task-10-lock-station.log
      2. Wait 1s. Verify host is not locked (nothing obstructs further commands).
      3. tmux send "ssh station 'echo still-here'" >> .sisyphus/evidence/task-10-lock-station.log
    Expected Result: EXIT=0; "still-here" echoed (session not actually locked because no locker is registered).
    Failure Indicators: EXIT non-zero (systemd refused the call), or the host actually locks and further commands hang.
    Evidence: .sisyphus/evidence/task-10-lock-station.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add omo-power-menu script`
  - Files: `modules/home-manager/desktop/omo-helpers.nix`
  - Pre-commit: `nix eval` on station

- [ ] 11. Add Hyprland binds via omo-helpers (station-only; overrides stock Super+W / Super+E without touching shared keybindings.nix)

  **What to do**:
  - **DO NOT TOUCH `modules/home-manager/desktop/hyprland/keybindings.nix`.** That file is imported by `modules/home-manager/desktop/hyprland/default.nix:16` and runs on all Hyprland hosts (laptop, VNPC-21, station). Editing it would change behavior on laptop + VNPC-21, violating the "other hosts unaffected" guarantee.
  - Instead, in `omo-helpers.nix` (conditional on `cfg.enable` → station only), add a `wayland.windowManager.hyprland.settings.bind` list with `lib.mkAfter` to ensure it concatenates AFTER keybindings.nix's list. Hyprland processes binds in-file order; later duplicates for the same (modmask, key) REPLACE earlier ones (verified via Hyprland wiki "multiple binds on the same key" behavior + real-world: `hyprctl reload` logs `keybind Super+W: already bound, overwriting`).
  - Inside `home-manager.users.${config.user}`:
    ```nix
    wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
      # Station-only: override stock Super+W / Super+E with launch-or-focus variants
      "$mainMod, W, exec, omo-launch-or-focus '${ZEN_CLASS_RE}' zen-beta"
      "$mainMod, E, exec, omo-launch-or-focus '${THUNAR_CLASS_RE}' thunar"
      # New additive binds (no conflicts — verified against full Super+Shift+* inventory)
      "$mainMod SHIFT, C, exec, hyprpicker -a -n && notify-send 'Picked' \"$(wl-paste)\" -t 2000"
      "$mainMod SHIFT, V, exec, omo-clipboard-pick"
      "$mainMod, period, exec, omo-emoji-pick"
      "$mainMod SHIFT, O, exec, omo-window-pop"
      "$mainMod SHIFT, E, exec, omo-power-menu"
    ];
    ```
  - `${ZEN_CLASS_RE}` and `${THUNAR_CLASS_RE}` come from T1 evidence (e.g., `"zen-beta|zen|Navigator"` and `"thunar|Thunar"`). These are interpolated into the final Nix string at module evaluation time; write them as literal strings directly in the `bind` entries.
  - `$mainMod` is defined in `keybindings.nix:6` (`"$mainMod" = "SUPER";`). Because `settings` is a single attrset shared across modules, `$mainMod` is available here too.
  - Verification approach (beyond eval): on station after rebuild, `hyprctl binds -j` will show TWO entries for Super+W (the stock `zen-beta` from keybindings.nix AND the new `omo-launch-or-focus` entry); Hyprland's runtime dispatch uses the LAST one registered. For acceptance, check that `hyprctl dispatch` on Super+W actually invokes `omo-launch-or-focus`, not just that the list contains it.

  **Must NOT do**:
  - Touch `modules/home-manager/desktop/hyprland/keybindings.nix` (would affect laptop + VNPC-21).
  - Use `lib.mkIf` inside the bind list (produces attrset, breaks list type).
  - Use `lib.mkForce` on `bind` — replaces the entire list, removing all stock binds.
  - Bind any new key that's already in use (Super+Shift+F is floating-toggle at line 49; Super+Shift+G is pypr daily at line 108; Super+Shift+W is wallpaper at line 33 — all preserved).
  - Add a bind for `omo-toggle-animations` (scope excluded; user can add manually later if desired).

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO (edits omo-helpers.nix — same file as other script tasks)
  - **Parallel Group**: Wave 3
  - **Blocks**: T14, F1-F4
  - **Blocked By**: T2, T3, T5, T7, T8, T9, T10

  **References**:
  - `modules/home-manager/desktop/hyprland/keybindings.nix:4-6` — confirms `config.home-manager.users.${config.user} = lib.mkIf config.hyprland.enable { wayland.windowManager.hyprland.settings = { "$mainMod" = "SUPER"; ... }; }`; settings attr shared across modules
  - `modules/home-manager/desktop/hyprland/keybindings.nix:34` — existing Super+W bind (stays; we override via mkAfter)
  - `modules/home-manager/desktop/hyprland/keybindings.nix:43` — existing Super+E bind (stays; we override via mkAfter)
  - `modules/home-manager/desktop/hyprland/default.nix:16` — shared import of keybindings.nix; WHY we DON'T edit that file
  - Hyprland wiki → "Binds" → "multiple binds on the same key" — later registration replaces earlier; same-key duplicates generate a warning but do NOT error
  - T1 evidence `.sisyphus/evidence/task-1-zen-thunar-classes.json` — source of `ZEN_CLASS_RE` and `THUNAR_CLASS_RE` inlined as string literals
  - Super+Shift inventory at `keybindings.nix:33, 49, 89-97, 108` — confirms C, V, O, E, and `.` (period) are unused

  **Acceptance Criteria**:
  - [ ] `modules/home-manager/desktop/hyprland/keybindings.nix` file UNCHANGED vs HEAD^ (verify via `git diff HEAD~1 HEAD -- modules/home-manager/desktop/hyprland/keybindings.nix` → empty)
  - [ ] `grep -c 'omo-launch-or-focus' modules/home-manager/desktop/omo-helpers.nix` → 2 (W + E)
  - [ ] `grep -c 'lib.mkAfter' modules/home-manager/desktop/omo-helpers.nix` → ≥ 1 (for the bind list)
  - [ ] After station rebuild: pressing Super+W invokes `omo-launch-or-focus` (verified via: running `hyprctl dispatch exec "pkill -f omo-launch-or-focus || true"` to clear, then `hyprctl dispatch sendkey SUPER_L+W` (if supported) OR by watching `hyprctl -j activewindow` change after manual Super+W press in tmux — primary check is the BEHAVIOR, not the bind-list content)
  - [ ] `hyprctl binds -j | jq '[.[] | select(.key == "W" and .modmask == 64 and (.dispatcher == "exec") and (.arg | contains("omo-launch-or-focus")))] | length'` → ≥ 1 (the override is registered)
  - [ ] `hyprctl binds -j | jq '[.[] | select(.arg | contains("omo-") or contains("hyprpicker"))] | length'` → ≥ 7 (W override, E override, Super+Shift+C hyprpicker, Super+Shift+V, Super+., Super+Shift+O, Super+Shift+E)
  - [ ] `nix eval` succeeds on all 3 desktop hosts
  - [ ] On laptop + VNPC-21: stock Super+W + Super+E binds UNCHANGED (manually verifiable post-rebuild; within-this-task check is that `keybindings.nix` is not diff-modified and `omo-helpers.enable = false` → no `bind` override added)

  **QA Scenarios**:

  ```
  Scenario: keybindings.nix is untouched (guarantees no regression on laptop/VNPC-21)
    Tool: Bash
    Preconditions: T11 commit created.
    Steps:
      1. git diff HEAD~1 HEAD -- modules/home-manager/desktop/hyprland/keybindings.nix | tee .sisyphus/evidence/task-11-keybindings-diff.log
      2. wc -l .sisyphus/evidence/task-11-keybindings-diff.log
    Expected Result: Diff file is empty (line count 0). Untouched.
    Failure Indicators: Any non-empty diff — violates "other hosts unaffected" guarantee.
    Evidence: .sisyphus/evidence/task-11-keybindings-diff.log

  Scenario: Station's omo overrides are registered with Hyprland
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T11 merged, station rebuilt.
    Steps:
      1. tmux send "ssh station 'hyprctl binds -j > /tmp/binds.json'"
      2. tmux send "ssh station 'jq \"[.[] | select(.key == \\\"W\\\" and .modmask == 64 and (.arg | contains(\\\"omo-launch-or-focus\\\")))] | length\" /tmp/binds.json'" > .sisyphus/evidence/task-11-W-override.log
      3. tmux send "ssh station 'jq \"[.[] | select(.key == \\\"E\\\" and .modmask == 64 and (.arg | contains(\\\"omo-launch-or-focus\\\")))] | length\" /tmp/binds.json'" > .sisyphus/evidence/task-11-E-override.log
      4. tmux send "ssh station 'jq \"[.[] | select(.arg | contains(\\\"omo-\\\") or contains(\\\"hyprpicker\\\"))] | length\" /tmp/binds.json'" > .sisyphus/evidence/task-11-all-omo.log
    Expected Result: W-override.log = 1 (or more if Hyprland lists duplicates); E-override.log = 1+; all-omo.log ≥ 7.
    Failure Indicators: W-override.log = 0 (mkAfter didn't append) or all-omo.log < 7 (missing binds).
    Evidence: .sisyphus/evidence/task-11-W-override.log, task-11-E-override.log, task-11-all-omo.log

  Scenario: Super+W BEHAVIOR dispatches omo-launch-or-focus (not bare zen-beta)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T11 merged, station rebuilt, Zen NOT currently running.
    Steps:
      1. tmux send "ssh station 'pgrep -f zen-beta && pkill -f zen-beta; sleep 1'" — ensure clean state
      2. tmux send "ssh station 'hyprctl dispatch exec \"omo-launch-or-focus zen-beta zen-beta\"'" — simulate Super+W press by invoking the override directly (acceptance proxy for keybind behavior, since sending synthetic SUPER+W from within tmux SSH is unreliable)
      3. Wait 3s.
      4. tmux send "ssh station 'hyprctl clients -j | jq \"[.[] | select((.class // \\\"\\\") | test(\\\"zen\\\";\\\"i\\\"))] | length\"'" > .sisyphus/evidence/task-11-w-behavior.log
    Expected Result: Exactly 1 Zen window open after invocation. Second invocation leaves it at 1 (focus, don't spawn).
    Failure Indicators: 0 windows (launch failed), or growing count on repeated calls.
    Evidence: .sisyphus/evidence/task-11-w-behavior.log

  Scenario: No regression on laptop / VNPC-21 (eval passes, keybindings.nix unchanged)
    Tool: Bash
    Preconditions: T11 committed.
    Steps:
      1. nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath 2>&1 | tee .sisyphus/evidence/task-11-laptop-eval.log
      2. nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath' 2>&1 | tee .sisyphus/evidence/task-11-vnpc21-eval.log
      3. nix eval .#nixosConfigurations.laptop.config.home-manager.users.none.wayland.windowManager.hyprland.settings.bind --json | jq '[.[] | select(. | contains("omo-"))] | length' | tee .sisyphus/evidence/task-11-laptop-omo-leak.log
    Expected Result: Both evals produce store paths; laptop-omo-leak count = 0 (no omo binds leaked to laptop).
    Failure Indicators: Any eval error; laptop-omo-leak > 0 (module not gated correctly).
    Evidence: .sisyphus/evidence/task-11-laptop-eval.log, .sisyphus/evidence/task-11-vnpc21-eval.log, .sisyphus/evidence/task-11-laptop-omo-leak.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): Hyprland keybinds + Super+W/E override (station-only)`
  - Files: `modules/home-manager/desktop/omo-helpers.nix` (ONLY — keybindings.nix is NOT edited)
  - Pre-commit: `nix eval` on all 3 desktop hosts

- [ ] 12. Animation toggle — source line + template + state file activation + `omo-toggle-animations`

  **What to do**:
  - **DO NOT EDIT `modules/home-manager/desktop/hyprland/default.nix`.** Instead, add the source line through `omo-helpers.nix` itself — home-manager's module system merges `extraConfig` strings across all contributing modules. Our `lib.mkAfter` block will concatenate after the shared module's `lib.mkAfter` block; both land after the settings section; order between the two `mkAfter` blocks is non-deterministic but they control independent settings (overrides.conf vs animations.conf) so no conflict.
  - Inside `home-manager.users.${config.user}` in `omo-helpers.nix`:
    ```nix
    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      # omo-helpers: runtime-toggleable animations via sourced state file
      source = ~/.local/state/hypr/animations.conf
    '';
    ```
  - Use `~/.local/state/hypr/animations.conf` directly — Hyprland expands `~` via POSIX glob. Using `${config.xdg.stateHome}` would Nix-interpolate the user's store-path XDG state dir at build time, which is not what we want (we want runtime `$HOME`). The literal `~/` form resolves at Hyprland-parse time to the user running Hyprland.
  - Ship a Nix-managed template with full animation config:
    ```nix
    xdg.configFile."hypr/omo-animations-on.conf".text = ''
      animations {
        enabled = true
        bezier = omoBezier, 0.05, 0.9, 0.1, 1.05
        animation = windows, 1, 4, omoBezier
        animation = windowsOut, 1, 4, default, popin 80%
        animation = border, 1, 10, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 2, default
      }
    '';
    ```
  - `home.activation.ensureOmoAnimationState` (mirrors `initHyprlandOverrides` at `default.nix:166-188`):
    ```nix
    home.activation.ensureOmoAnimationState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.local/state/hypr"
      if [ ! -f "$HOME/.local/state/hypr/animations.conf" ]; then
        touch "$HOME/.local/state/hypr/animations.conf"
      fi
    '';
    ```
  - `omo-toggle-animations` script:
    ```bash
    #!/usr/bin/env bash
    set -eu
    STATE="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/animations.conf"
    TPL="$HOME/.config/hypr/omo-animations-on.conf"
    if [ -s "$STATE" ]; then
      : > "$STATE"                 # truncate → off (Nix default applies)
      ${pkgs.libnotify}/bin/notify-send "Animations" "Off" -t 1500
    else
      cat "$TPL" > "$STATE"        # write full animation block → on
      ${pkgs.libnotify}/bin/notify-send "Animations" "On" -t 1500
    fi
    ${pkgs.hyprland}/bin/hyprctl reload >/dev/null
    ```
  - Add `"$mainMod SHIFT, A, exec, omo-toggle-animations"` to the bind list from T11? **No** — not required, user can invoke the command manually. Adding another keybind is out-of-scope (Metis: keep binds minimal). User can manually add later.

  **Must NOT do**:
  - Use `hyprctl keyword source` — additive, can't turn OFF (Metis section 7).
  - Touch settings.animations block in `default.nix` (line 82).
  - Add blur, gaps, rounding, or other toggle commands — one toggle only (Metis scope-creep guardrail).
  - Write an activation script without the `[ ! -f ... ]` guard (would reset toggle state on every rebuild).
  - Bind it to a new keybind.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Crosses three moving parts (Nix activation, runtime state, Hyprland reload)
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO (edits omo-helpers.nix)
  - **Parallel Group**: Wave 3 (parallel with T13 since they touch different files)
  - **Blocks**: T14, F1-F4
  - **Blocked By**: T2, T3

  **References**:
  - `modules/home-manager/desktop/hyprland/default.nix:160-188` — reference implementation of `source =` + guarded activation
  - `modules/home-manager/desktop/hyprland/default.nix:82-91` — existing animations block with curves pre-defined (target for override)
  - Metis section 7 (full) — NixOS `source =` live-toggle gotchas; the 7 documented pitfalls
  - XDG Base Directory Specification — `$XDG_STATE_HOME` defaults to `$HOME/.local/state`

  **Acceptance Criteria**:
  - [ ] `git diff HEAD~1 HEAD -- modules/home-manager/desktop/hyprland/default.nix` → empty (shared file untouched)
  - [ ] `~/.local/state/hypr/animations.conf` exists after rebuild (activation created it)
  - [ ] `wc -c < ~/.local/state/hypr/animations.conf` → 0 (empty = off by default)
  - [ ] `~/.config/hypr/omo-animations-on.conf` exists (Nix-managed, read-only store link)
  - [ ] `grep -c 'animations.conf' ~/.config/hypr/hyprland.conf` → ≥ 1 (source line present)
  - [ ] `omo-toggle-animations` twice (off→on→off) — each invocation flips `hyprctl getoption animations:enabled` value
  - [ ] State persists across `hyprctl reload` (file content is preserved)

  **QA Scenarios**:

  ```
  Scenario: Toggle off→on
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T12 merged, station rebuilt, state file empty.
    Steps:
      1. tmux send "ssh station 'hyprctl getoption animations:enabled -j | jq -r .int'" > /tmp/before.log
      2. tmux send "ssh station 'omo-toggle-animations; sleep 0.5; hyprctl getoption animations:enabled -j | jq -r .int'" > /tmp/after.log
      3. Combine into .sisyphus/evidence/task-12-toggle-on.log
    Expected Result: before = 0, after = 1.
    Failure Indicators: after = 0 (toggle failed); hyprctl error.
    Evidence: .sisyphus/evidence/task-12-toggle-on.log

  Scenario: Toggle on→off (reverse)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: previous scenario left animations on.
    Steps:
      1. tmux send "ssh station 'omo-toggle-animations; sleep 0.5; hyprctl getoption animations:enabled -j | jq -r .int'" > .sisyphus/evidence/task-12-toggle-off.log
      2. tmux send "ssh station 'wc -c < ~/.local/state/hypr/animations.conf'" >> .sisyphus/evidence/task-12-toggle-off.log
    Expected Result: First line = 0 (animations off); second line = 0 (state file empty).
    Failure Indicators: First line = 1 (failed to flip back); second line > 0 (state file not cleared).
    Evidence: .sisyphus/evidence/task-12-toggle-off.log

  Scenario: State persists across rebuild (toggle state survives `just rebuild`)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: animations currently ON (state file populated).
    Steps:
      1. tmux send "ssh station 'ls -la ~/.local/state/hypr/animations.conf; wc -c < ~/.local/state/hypr/animations.conf' > /tmp/before-rebuild.log"
      2. tmux send "ssh station 'just rebuild 2>&1 | tail -5'"
      3. tmux send "ssh station 'wc -c < ~/.local/state/hypr/animations.conf'" > .sisyphus/evidence/task-12-persistence.log
    Expected Result: Byte count after rebuild matches byte count before rebuild (>0 — template content preserved).
    Failure Indicators: Byte count drops to 0 after rebuild (activation script clobbered user state — indicates missing `[ ! -f ... ]` guard).
    Evidence: .sisyphus/evidence/task-12-persistence.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): add animation toggle with sourced state file`
  - Files: `modules/home-manager/desktop/omo-helpers.nix` (ONLY — shared hyprland/default.nix is NOT edited)
  - Pre-commit: `nix eval` on station + `git diff --name-only HEAD~1 HEAD | grep -v '^modules/home-manager/desktop/omo-helpers.nix$' | wc -l` → 0 (only this one file changed)

- [ ] 13. Waybar power icon — station-only deployment via post-init activation (shared source files UNTOUCHED)

  **What to do**:
  - **DO NOT EDIT `modules/home-manager/desktop/hyprland/config/waybar/config` or `.../style.css`.** Those files are deployed to ALL desktops via `packages.nix:92` (`"waybar-base".source = ./config/waybar;`) and `packages.nix:98-108` (`initWaybar` activation). Editing them changes behavior on laptop + VNPC-21 the next time their waybar config is reset.
  - Instead, in `omo-helpers.nix` (gated by `cfg.enable` → station only), add TWO activation scripts that run AFTER `initWaybar` and patch the deployed waybar config in-place on station:
    ```nix
    # Patch config JSON to add custom/power module (only if missing)
    home.activation.omoWaybarPatchConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      WAYBAR_CFG="$HOME/.config/waybar/config"
      if [ -f "$WAYBAR_CFG" ] && ! ${pkgs.jq}/bin/jq -e '."modules-right" | index("custom/power")' "$WAYBAR_CFG" >/dev/null 2>&1; then
        TMP=$(mktemp)
        ${pkgs.jq}/bin/jq '
          ."modules-right" += ["custom/power"] |
          ."custom/power" = {
            "format": "\u{f011}",
            "tooltip": true,
            "tooltip-format": "Power Menu",
            "on-click": "omo-power-menu"
          }
        ' "$WAYBAR_CFG" > "$TMP" && mv "$TMP" "$WAYBAR_CFG"
    ```
    NOTE on the power glyph: The `"format"` value must be the literal Nerd Font character U+F011 (nf-fa-power_off). In Nix strings, write it as `"\u{f011}"` or paste the raw glyph. The executor MUST verify the glyph renders in waybar by checking `jq -r '.["custom/power"].format' ~/.config/waybar/config | xxd | head -1` — expect bytes `ef 80 91` (UTF-8 encoding of U+F011). If the character does not render, substitute with a simpler Unicode symbol like `"⏻"` (U+23FB) and test font fallback.
        chmod u+w "$WAYBAR_CFG"
      fi
    '';

    # Append #custom-power CSS rule (only if missing)
    home.activation.omoWaybarPatchStyle = lib.hm.dag.entryAfter [ "omoWaybarPatchConfig" ] ''
      WAYBAR_CSS="$HOME/.config/waybar/style.css"
      if [ -f "$WAYBAR_CSS" ] && ! grep -q "#custom-power" "$WAYBAR_CSS"; then
        cat >> "$WAYBAR_CSS" <<'EOF'

    #custom-power {
      color: @red;
      padding: 0 10px;
    }
    EOF
      fi
    '';
    ```
  - The `jq` patch is **idempotent** (the `| index(...)` guard skips re-patching on subsequent rebuilds). CSS is appended only if the selector is missing.
  - Activation ordering: both run `after = [ "linkGeneration" ]` (matching `initWaybar` at `packages.nix:99`) — NixOS activation executes scripts in lexical attribute-name order within the same "after" bucket. To guarantee our scripts run AFTER `initWaybar`, the second uses `after = [ "omoWaybarPatchConfig" ]` and the first uses the generic `writeBoundary` anchor which follows the linkGeneration phase. Alternative: use `after = [ "initWaybar" ]` explicitly (preferred, unambiguous) — verify by reading `packages.nix:98-108` for the exact activation name.
  - Note on `pkill -SIGUSR2 waybar`: waybar reloads its config on SIGUSR2. After activation patches, send SIGUSR2 if waybar is running, ignoring if it isn't:
    ```nix
    home.activation.omoWaybarReload = lib.hm.dag.entryAfter [ "omoWaybarPatchStyle" ] ''
      ${pkgs.procps}/bin/pkill -SIGUSR2 -x waybar 2>/dev/null || true
    '';
    ```
  - First-time dry-run: if `~/.config/waybar/config` doesn't exist yet (fresh install), the patch scripts skip silently via the `[ -f ]` guard; the `initWaybar` stock deployment runs first, then next activation cycle our patches land. Acceptable.

  **Must NOT do**:
  - Edit `modules/home-manager/desktop/hyprland/config/waybar/config` or `style.css` (shared source — would affect laptop + VNPC-21).
  - Edit `modules/home-manager/desktop/hyprland/packages.nix` (shared activation).
  - Add any waybar module beyond `custom/power`.
  - Add color rules for modules other than `#custom-power`.
  - Use Nord hex values — use `@red` (Catppuccin Macchiato, via the shared `@import url("macchiato.css");`).
  - Use Unicode `⏻` (U+23FB) — use Nerd Font `` (U+F011, `nf-fa-power_off`).
  - Fail silently if waybar is running but SIGUSR2 didn't reload — log the attempt (the `|| true` handles missing process, but if reload itself errors, surface it in activation logs).

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — JSON + CSS + activation-script interaction
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: YES with T12 (different files)
  - **Parallel Group**: Wave 3
  - **Blocks**: T14, F1-F4
  - **Blocked By**: T2, T3, T10 (power menu script must exist for waybar click target)

  **References**:
  - `modules/home-manager/desktop/hyprland/packages.nix:92` — `"waybar-base".source = ./config/waybar;` (shared source; DO NOT EDIT)
  - `modules/home-manager/desktop/hyprland/packages.nix:98-108` — stock `initWaybar` activation; our patches run after it and target the MUTABLE deployed copy at `~/.config/waybar/`, not the shared source
  - `modules/home-manager/desktop/hyprland/config/waybar/style.css:1` — shared `@import url("macchiato.css");` → Catppuccin palette; our `#custom-power` rule uses `@red` from this palette (inherited — we don't import macchiato in our patch, just rely on the stock style.css already importing it)
  - Nerd Font cheat sheet — `nf-fa-power_off` = U+F011 = `` (reliable in JetBrainsMono Nerd Font)
  - `lib.hm.dag.entryAfter` documentation — home-manager DAG-based activation ordering

  **Acceptance Criteria**:
  - [ ] `git diff HEAD~1 HEAD -- modules/home-manager/desktop/hyprland/config/waybar/` → empty (shared source files unchanged)
  - [ ] `git diff HEAD~1 HEAD -- modules/home-manager/desktop/hyprland/packages.nix` → empty (shared activation unchanged)
  - [ ] `grep -c 'omoWaybarPatchConfig' modules/home-manager/desktop/omo-helpers.nix` → 1
  - [ ] `grep -c 'omoWaybarPatchStyle' modules/home-manager/desktop/omo-helpers.nix` → 1
  - [ ] After station rebuild: `jq '."modules-right" | index("custom/power")' ~/.config/waybar/config` → integer (not null)
  - [ ] After station rebuild: `grep -q '#custom-power' ~/.config/waybar/style.css`
  - [ ] Idempotency: running `home-manager switch` a second time does NOT duplicate the module or re-append the CSS rule
  - [ ] Laptop + VNPC-21 waybar config UNCHANGED: `ssh laptop 'jq ."custom/power" ~/.config/waybar/config' → null` (skip if laptop not rebuilt; build-eval diff check is primary)
  - [ ] Waybar renders the power icon (visually confirmed via screenshot in F3)
  - [ ] Clicking the icon (or calling `omo-power-menu` directly) opens the rofi power menu

  **QA Scenarios**:

  ```
  Scenario: Shared waybar source files UNTOUCHED
    Tool: Bash
    Preconditions: T13 commit created.
    Steps:
      1. git diff HEAD~1 HEAD -- modules/home-manager/desktop/hyprland/config/waybar/ | tee .sisyphus/evidence/task-13-source-diff.log
      2. git diff HEAD~1 HEAD -- modules/home-manager/desktop/hyprland/packages.nix | tee -a .sisyphus/evidence/task-13-source-diff.log
      3. wc -l .sisyphus/evidence/task-13-source-diff.log
    Expected Result: Both diffs empty (line count 0 for both). Only omo-helpers.nix was edited.
    Failure Indicators: Non-empty diff — violates "other hosts unaffected".
    Evidence: .sisyphus/evidence/task-13-source-diff.log

  Scenario: Deployed waybar config on station has power module after rebuild
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T13 merged, `just rebuild` run on station.
    Steps:
      1. tmux send "ssh station 'jq \".\\\"modules-right\\\" | index(\\\"custom/power\\\")\" ~/.config/waybar/config'" > .sisyphus/evidence/task-13-deployed-array.log
      2. tmux send "ssh station 'jq \".\\\"custom/power\\\"\" ~/.config/waybar/config'" > .sisyphus/evidence/task-13-deployed-module.log
      3. tmux send "ssh station 'grep -c \"#custom-power\" ~/.config/waybar/style.css'" > .sisyphus/evidence/task-13-deployed-css.log
    Expected Result: array log = integer ≥ 0 (not null); module log contains a non-empty `"format"` value (the Nerd Font U+F011 glyph, UTF-8 bytes `ef 80 91`) and `"on-click": "omo-power-menu"`; css log = 1.
    Failure Indicators: array = "null" (patch didn't run), module log = "null", css log = 0.
    Evidence: .sisyphus/evidence/task-13-deployed-{array,module,css}.log

  Scenario: Patch is idempotent across multiple rebuilds
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: T13 activated once; power module in place.
    Steps:
      1. tmux send "ssh station 'BEFORE_COUNT=\$(jq \"[.\\\"modules-right\\\"[] | select(. == \\\"custom/power\\\")] | length\" ~/.config/waybar/config); echo BEFORE=\$BEFORE_COUNT'" > .sisyphus/evidence/task-13-idem.log
      2. tmux send "ssh station 'home-manager switch 2>&1 | tail -3'" — trigger activation again
      3. tmux send "ssh station 'AFTER_COUNT=\$(jq \"[.\\\"modules-right\\\"[] | select(. == \\\"custom/power\\\")] | length\" ~/.config/waybar/config); echo AFTER=\$AFTER_COUNT'" >> .sisyphus/evidence/task-13-idem.log
      4. tmux send "ssh station 'CSS_COUNT=\$(grep -c \"#custom-power\" ~/.config/waybar/style.css); echo CSS=\$CSS_COUNT'" >> .sisyphus/evidence/task-13-idem.log
    Expected Result: BEFORE=1, AFTER=1 (not 2 — no duplicate entry); CSS=1 (single rule, not appended twice).
    Failure Indicators: AFTER=2, CSS=2 or more — idempotency broken.
    Evidence: .sisyphus/evidence/task-13-idem.log

  Scenario: Clicking power icon launches power menu (behavior test)
    Tool: interactive_bash (tmux SSH to station)
    Preconditions: waybar running with power module; T10 script installed.
    Steps:
      1. tmux send "ssh station 'pgrep -c -x rofi'" > /tmp/rofi-before.txt — expect 0
      2. tmux send "ssh station 'omo-power-menu &'" — simulate click via direct invocation (mirrors what waybar `on-click` does)
      3. Wait 1.5s.
      4. tmux send "ssh station 'pgrep -c -x rofi'" > .sisyphus/evidence/task-13-click.log — expect ≥ 1
      5. tmux send "ssh station 'pkill -x rofi'" — clean up.
    Expected Result: rofi process appears after invocation.
    Failure Indicators: rofi count stays at 0 (omo-power-menu not in PATH or crashed).
    Evidence: .sisyphus/evidence/task-13-click.log
  ```

  **Commit**: YES
  - Message: `feat(omo-helpers): station-only waybar power icon patch`
  - Files: `modules/home-manager/desktop/omo-helpers.nix` (ONLY — shared waybar files untouched)
  - Pre-commit: `nix eval` on station + confirm `git diff --name-only HEAD~1 HEAD` shows ONLY `modules/home-manager/desktop/omo-helpers.nix`

- [ ] 14. Cross-host eval regression check

  **What to do**:
  - Run `nix eval` on all 3 desktop host configurations. All must succeed, confirming that:
    - The new module's imports don't break eval on hosts where `omo-helpers.enable = false`.
    - T11 did NOT edit `keybindings.nix` (verify via git diff) — so laptop + VNPC-21 Hyprland binds are identical to pre-plan.
    - T13 did NOT edit shared waybar source files (verify via git diff) — so laptop + VNPC-21 waybar config renders identically to pre-plan (no `custom/power` module on their deployed configs).
  - Capture evidence logs.

  **Must NOT do**:
  - Rebuild laptop or vnpc-21.
  - Modify any files in this task.
  - Deploy or test runtime behavior on other hosts.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: none

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4
  - **Blocks**: F1-F4
  - **Blocked By**: T11, T12, T13

  **References**:
  - `flake.nix` — entry point for `nix eval`
  - `parts/hosts.nix:35-41` — where `laptop`, `VNPC-21` (uppercase!), `station` are wired as nixosConfigurations. Note: `VNPC-21` attr name must be quoted in shell (`'.#nixosConfigurations."VNPC-21"...'`)

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` → store path
  - [ ] `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` → store path
  - [ ] `nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath'` → store path
  - [ ] `nix eval .#nixosConfigurations.laptop.config.omo-helpers.enable` → `false`
  - [ ] `nix eval '.#nixosConfigurations."VNPC-21".config.omo-helpers.enable'` → `false`
  - [ ] Shared source-file integrity: Before execution begins, record baseline SHA via `git rev-parse HEAD > .sisyphus/evidence/baseline-sha.txt`. Then at T14: `git diff $(cat .sisyphus/evidence/baseline-sha.txt) HEAD -- modules/home-manager/desktop/hyprland/keybindings.nix modules/home-manager/desktop/hyprland/default.nix modules/home-manager/desktop/hyprland/packages.nix modules/home-manager/desktop/hyprland/config/` → empty (no shared Hyprland/waybar/rofi source files changed during the plan's execution)
  - [ ] Package leakage check on laptop: `nix eval .#nixosConfigurations.laptop.config.home-manager.users.none.home.packages --apply 'ps: builtins.filter (p: (p.pname or p.name or "") == "cliphist" || (p.pname or p.name or "") == "hyprpicker" || (p.pname or p.name or "") == "rofi-emoji") ps | builtins.length'` → 0 (no omo-helpers packages landed on laptop).

  **QA Scenarios**:

  ```
  Scenario: All 3 desktops evaluate successfully
    Tool: Bash
    Preconditions: T11, T12, T13 all committed.
    Steps:
      1. nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath 2>&1 | tee .sisyphus/evidence/task-14-station.log
      2. nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath 2>&1 | tee .sisyphus/evidence/task-14-laptop.log
      3. nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath' 2>&1 | tee .sisyphus/evidence/task-14-vnpc21.log
    Expected Result: Each file starts with `/nix/store/...`; all exit 0.
    Failure Indicators: "error:", non-zero exit, missing attribute errors.
    Evidence: .sisyphus/evidence/task-14-{station,laptop,vnpc21}.log

  Scenario: omo-helpers disabled on other hosts (no package leakage)
    Tool: Bash
    Preconditions: T14 step 1 passed.
    Steps:
      1. nix eval .#nixosConfigurations.laptop.config.omo-helpers.enable 2>&1 | tee .sisyphus/evidence/task-14-laptop-flag.log
      2. nix eval '.#nixosConfigurations."VNPC-21".config.omo-helpers.enable' 2>&1 | tee .sisyphus/evidence/task-14-vnpc21-flag.log
      3. nix eval .#nixosConfigurations.station.config.omo-helpers.enable 2>&1 | tee .sisyphus/evidence/task-14-station-flag.log
    Expected Result: laptop + vnpc-21 → "false"; station → "true".
    Failure Indicators: any mismatch.
    Evidence: .sisyphus/evidence/task-14-{laptop,vnpc21,station}-flag.log
  ```

  **Commit**: NO (verification only; no file changes)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and wait for explicit "okay" before marking work complete.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command, check hyprctl output on station via tmux). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `nix fmt` check on all edited `.nix` files. Run `nix eval` on all 3 desktop hosts (station, laptop, vnpc-21). Review omo-helpers.nix + scripts for: hardcoded paths (`/home/none/`), missing `cfg` binding, `lib.mkIf` inside lists, missing `home-manager.users.${config.user}` wrapper, scripts exceeding 30 lines, per-feature sub-options, use of forbidden runtime deps. Check AI slop: excessive comments, color output, unused imports, shared helper functions between scripts.
  Output: `Fmt [PASS/FAIL] | Eval station [PASS/FAIL] | Eval laptop [PASS/FAIL] | Eval vnpc-21 [PASS/FAIL] | Scripts [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA on Station** — `unspecified-high`
  SSH or local-exec to station. Execute every QA scenario from every task: verify all 7 `omo-*` scripts in PATH, trigger every new keybind via `hyprctl dispatch`, click the waybar power icon (simulate via `omo-power-menu` direct invocation), cycle `omo-toggle-animations` both ways, verify cliphist writes/reads entries. Test cross-task integration: toggle animations on → open power menu → close → toggle off. Test edge cases: window-pop on tiled window, on floating window, on fullscreen window; power menu on station (lock/suspend should fail gracefully with notification or no-op). Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read the actual diff (git log + git diff). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance per task (e.g., T6 did NOT download favicons; T11 did NOT touch lines in keybindings.nix other than 34 + 43). Detect cross-task contamination (Task N touching Task M's files). Flag unaccounted-for changes (new `.rasi` files, new CSS files, new modules beyond omo-helpers.nix).
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **T1**: no commit (validation-only; result captured to `.sisyphus/evidence/`)
- **T2**: `feat(station): scaffold omo-helpers module` — `modules/home-manager/desktop/omo-helpers.nix`, `modules/home-manager/desktop/default.nix` (or wherever import lives), `hosts/station/default.nix`; pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath`
- **T3**: `feat(omo-helpers): add desktop-UX packages` — `omo-helpers.nix` (packages block); pre-commit: `nix eval` on station
- **T4**: `feat(omo-helpers): enable cliphist user service` — `omo-helpers.nix`; pre-commit: `nix eval` on station
- **T5**: `feat(omo-helpers): add omo-launch-or-focus script` — `omo-helpers.nix`; pre-commit: `nix eval` on station
- **T6**: `feat(omo-helpers): add omo-webapp-install script` — `omo-helpers.nix`; pre-commit: `nix eval` on station
- **T7**: `feat(omo-helpers): add omo-window-pop script` — `omo-helpers.nix`; pre-commit: `nix eval` on station
- **T8**: `feat(omo-helpers): add omo-clipboard-pick script` — `omo-helpers.nix`; pre-commit: `nix eval` on station
- **T9**: `feat(omo-helpers): add omo-emoji-pick script` — `omo-helpers.nix`; pre-commit: `nix eval` on station
- **T10**: `feat(omo-helpers): add omo-power-menu script` — `omo-helpers.nix`; pre-commit: `nix eval` on station
- **T11**: `feat(omo-helpers): Hyprland keybinds + Super+W/E override (station-only)` — `modules/home-manager/desktop/omo-helpers.nix` ONLY (shared `keybindings.nix` UNCHANGED); pre-commit: `nix eval` on all 3 desktop hosts + `git diff --name-only HEAD~1 HEAD | grep -v omo-helpers.nix | wc -l` → 0
- **T12**: `feat(omo-helpers): add animation toggle with sourced state file` — `modules/home-manager/desktop/omo-helpers.nix` ONLY (shared `hyprland/default.nix` UNCHANGED); pre-commit: `nix eval` on station
- **T13**: `feat(omo-helpers): station-only waybar power icon patch` — `modules/home-manager/desktop/omo-helpers.nix` ONLY (shared `config/waybar/config` + `style.css` + `packages.nix` UNCHANGED); pre-commit: `nix eval` on station + `git diff --name-only HEAD~1 HEAD | grep -v omo-helpers.nix | wc -l` → 0
- **T14**: no commit (cross-host eval verification)

**Rebuild instructions** (no special reset needed): T13's patch activation runs AFTER the stock `initWaybar` and patches the deployed `~/.config/waybar/config` directly via `jq` (idempotent). No manual `rm -rf ~/.config/waybar` is required. `just rebuild` on station is sufficient.

---

## Success Criteria

### Verification Commands
```bash
# Build eval (all desktop hosts)
nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
nix eval '.#nixosConfigurations."VNPC-21".config.system.build.toplevel.drvPath'   # note: uppercase VNPC-21 per parts/hosts.nix:37

# Scripts in PATH on station
for s in omo-launch-or-focus omo-webapp-install omo-window-pop omo-power-menu \
         omo-toggle-animations omo-clipboard-pick omo-emoji-pick; do
  command -v $s || echo "MISSING: $s"
done

# Cliphist service
systemctl --user is-active cliphist  # expect: active

# Keybinds registered (station)
hyprctl binds -j | jq '[.[] | {mod: .modmask, key: .key, arg: .arg}] | map(select(.arg | contains("omo-")))'

# Super+W and Super+E now call omo-launch-or-focus
hyprctl binds -j | jq '.[] | select(.key == "W" and .modmask == 64) | .arg'  # contains "omo-launch-or-focus"
hyprctl binds -j | jq '.[] | select(.key == "E" and .modmask == 64) | .arg'  # contains "omo-launch-or-focus"

# Waybar power module present in DEPLOYED station config (NOT shared source — source is untouched)
ssh station 'jq ."modules-right" ~/.config/waybar/config | jq "index(\"custom/power\")"'  # expect: number (not null)

# Animations state file exists + empty (off by default)
test -f "$HOME/.local/state/hypr/animations.conf" && test ! -s "$HOME/.local/state/hypr/animations.conf" && echo OK

# Source line present in deployed hyprland.conf
grep -c "animations.conf" ~/.config/hypr/hyprland.conf  # expect: >= 1
```

### Final Checklist
- [ ] All "Must Have" present (verified by F1)
- [ ] All "Must NOT Have" absent (verified by F4)
- [ ] `nix eval` succeeds on station, laptop, vnpc-21
- [ ] All 7 `omo-*` scripts in PATH on station
- [ ] 5 new keybinds registered; Super+W + Super+E rewired via `omo-launch-or-focus`
- [ ] Cliphist service active; clipboard history recordable + pickable
- [ ] Waybar shows power icon; click launches power menu
- [ ] `omo-toggle-animations` flips animations without rebuild; state persists across reboot
- [ ] Laptop + VNPC-21 keybindings + waybar + rofi unchanged (regression-free)
- [ ] F1, F2, F3, F4 all APPROVE
- [ ] User gives explicit OK
