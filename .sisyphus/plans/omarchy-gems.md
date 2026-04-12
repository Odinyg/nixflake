# Omarchy Gems — Extract Best Patterns into NixOS Desktop

## TL;DR

> **Quick Summary**: Port 4 high-value patterns from Basecamp's Omarchy dotfiles into the existing NixOS Hyprland desktop configuration: web app launchers, discoverable keybindings, shell function libraries, and an advanced screenshot script.
> 
> **Deliverables**:
> - 7 web app desktop entries + launch-or-focus script + documented template for adding more
> - All 62 Hyprland keybindings converted from `bind` to `bindd` (discoverable descriptions)
> - 3 shell function libraries (compression, SSH forwarding, git worktrees) as sourced zsh files
> - Robust screenshot script replacing current one-liners (region/window/fullscreen + rotation handling + notifications)
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 3 waves
> **Critical Path**: Task 6 (screenshot script) → Task 9 (keybinding conversion)

---

## Context

### Original Request
User wanted to explore Basecamp's Omarchy repository (https://github.com/basecamp/omarchy) and extract useful patterns for their NixOS Hyprland desktop setup.

### Interview Summary
**Key Discussions**:
- Researched Omarchy thoroughly: 210 utility scripts, 373 config templates, 19 themes, Hyprland-based
- Mapped user's existing setup: Hyprland, Zsh, Starship, Ghostty, tmux, neovim (nixvim), lazygit, Stylix/Nord, grim+slurp+satty
- Identified 7 potential gems, user selected 4: web app launchers, bindd keybindings, shell functions, screenshot script
- User specified 7 web apps + wants a template for adding more later
- Shell functions: compression, SSH port forwarding, git worktrees (user chose these 3)
- All 3 desktops targeted: laptop, station, vnpc-21

**Research Findings**:
- Omarchy's `launch-or-focus` uses `hyprctl clients -j` + jq to prevent duplicate app windows
- Omarchy's `bindd` format: `bindd = MODS, KEY, Description, dispatcher, args` — descriptions make shortcuts discoverable
- Omarchy's shell functions are modular per-category files, worktrees use `gum` for TUI confirms
- Station has a rotated monitor (DP-2, transform 3 = 270°) — screenshot script must handle this
- Chromium `--app=URL` window class is `chrome-<domain>-*` — existing window rule at `default.nix:143` already applies borderless styling
- User's git aliases occupy `ga`, `gd`, `gb`, `gc`, `gm`, `gf`, etc. — worktree functions must use `gwt` prefix to avoid conflicts

### Metis Review
**Identified Gaps** (addressed):
- Must use `chromium` binary (not `google-chrome`) — only `chromium` has Wayland flags configured
- `gum` package not installed — must add to system-tools.nix for worktree TUI confirms
- `zip`/`unzip` not in any package list — must add for compression helpers
- Shell functions must use sourced files pattern (precedent: `zsh.nix:63-67` sources `quote.sh`)
- All 4 binding types need `d` variants: `bind`→`bindd`, `bindm`→`binddm`, `bindel`→`binddel`, `bindl`→`binddl`
- Bash `read -p` doesn't work in zsh — must adapt all `read` calls
- Screenshot script must handle display rotation for station's DP-2 (transform 270°)
- launch-or-focus must handle first-launch latency (Chromium cold start 1-3s)
- `.desktop` entries MUST NOT set `mimeType` — Zen Browser owns URL handlers
- No comma characters in bindd descriptions — would corrupt Hyprland's comma-delimited parser

---

## Work Objectives

### Core Objective
Integrate 4 curated patterns from Omarchy into the NixOS desktop modules, maintaining existing conventions and working across all 3 desktop hosts.

### Concrete Deliverables
- `modules/home-manager/misc/web-apps.nix` — new module with 7 web app desktop entries + launch-or-focus script
- `modules/home-manager/misc/default.nix` — updated import list
- `modules/home-manager/desktop/hyprland/scripts/screenshot.sh` — robust screenshot script
- `modules/home-manager/cli/zsh/scripts/compression.zsh` — compression functions
- `modules/home-manager/cli/zsh/scripts/ssh-forwarding.zsh` — SSH port forwarding functions
- `modules/home-manager/cli/zsh/scripts/git-worktrees.zsh` — git worktree functions
- `modules/home-manager/cli/zsh/zsh.nix` — updated to source new function files
- `modules/home-manager/cli/system-tools.nix` — updated with gum, zip, unzip
- `modules/home-manager/desktop/hyprland/keybindings.nix` — converted to bindd + screenshot script bindings

### Definition of Done
- [ ] `just rebuild` succeeds on current host
- [ ] All 7 web apps launchable via rofi
- [ ] `hyprctl binds -j | jq '[.[] | select(.has_description == true)] | length'` equals total binding count
- [ ] `zsh -ic 'type compress'` returns "shell function"
- [ ] Screenshot script captures region, window, and fullscreen modes

### Must Have
- All 7 web app desktop entries using `chromium --app=URL`
- launch-or-focus prevents duplicate windows with retry logic for cold starts
- Template comment in `web-apps.nix` showing how to add new web apps
- All 62 keybindings converted to descriptive variants (bindd/binddm/binddel/binddl)
- Screenshot script handles region, window, fullscreen modes
- Screenshot script handles station's rotated DP-2 monitor (transform 270°)
- Shell functions use sourced files under `zsh/scripts/`, not inline initContent
- Worktree functions use `gwt` prefix (not `ga`/`gd` which conflict with git aliases)
- All functions are zsh-compatible (no bash-only syntax like `read -p`)

### Must NOT Have (Guardrails)
- NO `mimeType` on web app `.desktop` entries — Zen Browser owns URL handlers
- NO per-app enable toggles — single `web-apps.enable` for the whole module
- NO icon downloads/favicon management — use `icon = "chromium"` or omit
- NO keybinding behavior changes — bindd conversion is PURELY adding descriptions
- NO commas in bindd descriptions — would corrupt Hyprland parser
- NO hardcoded `/home/odin/` or `/home/none/` paths — use `$HOME` only
- NO shell function names that conflict with existing aliases (`ga`, `gd`, `gb`, `gc`, `gm`, `gf`, `g`, `lg`)
- NO `google-chrome` binary — only `chromium` (has Wayland flags)
- NO more than 15 total shell functions across all 3 categories
- NO screenshot timer/delay/clipboard-history features — out of scope
- NO notification actions beyond "Edit in Satty" — one action only

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: N/A (NixOS desktop configuration, not application code)
- **Automated tests**: None — this is declarative Nix config + shell scripts
- **Framework**: N/A

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Desktop/UI verification**: Use interactive_bash (tmux) — rebuild, check Hyprland bindings
- **Shell functions**: Use Bash — test function definitions, run compression/extraction
- **Web apps**: Use Bash — verify .desktop files, test launch-or-focus
- **Screenshot**: Use Bash — verify script exists and is executable, test fullscreen mode

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — all independent, max parallel):
├── Task 1: Add missing packages (gum, zip, unzip) to system-tools.nix [quick]
├── Task 2: Create launch-or-focus script [quick]
├── Task 3: Create compression.zsh function file [quick]
├── Task 4: Create ssh-forwarding.zsh function file [quick]
├── Task 5: Create git-worktrees.zsh function file [quick]
└── Task 6: Create screenshot.sh script [unspecified-high]

Wave 2 (After Wave 1 — wire everything together):
├── Task 7: Wire shell functions into zsh.nix (depends: 1, 3, 4, 5) [quick]
├── Task 8: Create web-apps.nix module with desktop entries (depends: 2) [unspecified-high]
└── Task 9: Convert keybindings to bindd + replace screenshot bindings (depends: 6) [unspecified-high]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay
```

**Critical Path**: Task 6 → Task 9 → F1-F4 → user okay
**Parallel Speedup**: ~60% faster than sequential
**Max Concurrent**: 6 (Wave 1)

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1 | — | 7 | 1 |
| 2 | — | 8 | 1 |
| 3 | — | 7 | 1 |
| 4 | — | 7 | 1 |
| 5 | — | 7 | 1 |
| 6 | — | 9 | 1 |
| 7 | 1, 3, 4, 5 | F1-F4 | 2 |
| 8 | 2 | F1-F4 | 2 |
| 9 | 6 | F1-F4 | 2 |
| F1-F4 | 7, 8, 9 | user okay | FINAL |

### Agent Dispatch Summary

- **Wave 1**: **6 tasks** — T1 → `quick`, T2 → `quick`, T3 → `quick`, T4 → `quick`, T5 → `quick`, T6 → `unspecified-high`
- **Wave 2**: **3 tasks** — T7 → `quick`, T8 → `unspecified-high`, T9 → `unspecified-high`
- **FINAL**: **4 tasks** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Add missing packages to system-tools.nix

  **What to do**:
  - Add `gum` (TUI confirm tool, needed for git worktree functions)
  - Add `zip` and `unzip` (needed for compression helpers)
  - Add these to the existing `home.packages` list in `system-tools.nix`

  **Must NOT do**:
  - Do NOT reorganize existing packages or change comments
  - Do NOT add packages beyond gum, zip, unzip

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file, 3 lines added to a package list
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:
  - `modules/home-manager/cli/system-tools.nix:10-37` — Existing package list; add new packages in appropriate sections with comments
  - `modules/home-manager/cli/zsh/scripts/git-worktrees.zsh` (Task 5 output) — Why `gum` is needed: TUI confirmation dialogs for worktree deletion

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Packages evaluate correctly in Nix
    Tool: Bash
    Preconditions: None
    Steps:
      1. Run: nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
      2. Verify exit code 0
    Expected Result: Nix evaluation succeeds without errors
    Failure Indicators: Nix evaluation error mentioning undefined package
    Evidence: .sisyphus/evidence/task-1-nix-eval.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Message: `feat(desktop): add Omarchy-inspired gems — web apps, bindd, shell functions, screenshot`
  - Files: `modules/home-manager/cli/system-tools.nix`

---

- [x] 2. Create launch-or-focus script

  **What to do**:
  - Create a `launch-or-focus` shell script that:
    1. Takes two arguments: `WINDOW_PATTERN` and `LAUNCH_COMMAND`
    2. Queries `hyprctl clients -j` to find existing window matching pattern (class or title, case-insensitive)
    3. If found → focus it via `hyprctl dispatch focuswindow address:$ADDRESS`
    4. If not found → launch the command, then retry focus after 2-second delay (handles Chromium cold start latency)
  - Package it via `pkgs.writeShellScriptBin "launch-or-focus"` inside the web-apps module (Task 8 will create the module; this task creates the script content)
  - For now, create the script as a standalone file at `modules/home-manager/misc/scripts/launch-or-focus.sh`

  **Must NOT do**:
  - Do NOT hardcode any application names or URLs
  - Do NOT use `google-chrome` — this is a generic launcher
  - Do NOT add complex retry logic beyond one sleep+retry cycle

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single script file, ~25 lines, clear specification from Omarchy reference
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4, 5, 6)
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - Omarchy's `bin/omarchy-launch-or-focus` — Source pattern: uses `hyprctl clients -j | jq -r --arg p "$WINDOW_PATTERN" '.[]|select((.class|test("\\b" + $p + "\\b";"i")) or (.title|test("\\b" + $p + "\\b";"i")))|.address' | head -n1`
  - `modules/home-manager/desktop/hyprland/default.nix:143` — Existing window rule `match:class ^(chrome-.*)` confirms Chromium --app window class format is `chrome-<domain>-*`
  - `modules/home-manager/desktop/hyprland/packages.nix:85-88` — Pattern for placing scripts: `xdg.configFile` with `executable = true`; however, this script should use `writeShellScriptBin` to be in PATH

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Script file exists and is syntactically valid
    Tool: Bash
    Preconditions: Script file created
    Steps:
      1. Run: bash -n modules/home-manager/misc/scripts/launch-or-focus.sh
      2. Verify exit code 0
      3. Run: shellcheck modules/home-manager/misc/scripts/launch-or-focus.sh
    Expected Result: No syntax errors, shellcheck clean
    Failure Indicators: Syntax error or shellcheck warning
    Evidence: .sisyphus/evidence/task-2-shellcheck.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Files: `modules/home-manager/misc/scripts/launch-or-focus.sh`

---

- [x] 3. Create compression.zsh shell function file

  **What to do**:
  - Create `modules/home-manager/cli/zsh/scripts/compression.zsh` with these functions:
    - `compress()` — Takes a directory, creates `dirname.tar.gz`: `tar -czf "${1%/}.tar.gz" "${1%/}"`
    - `compress_zip()` — Takes a directory, creates `dirname.zip`: `zip -r "${1%/}.zip" "${1%/}"`
    - `extract()` — Smart extraction based on file extension: handles `.tar.gz`, `.tgz`, `.tar.bz2`, `.tar.xz`, `.zip`, `.gz`, `.bz2`, `.xz`, `.7z`, `.rar`
      - Use a case statement on the filename extension
      - For `.tar.*` files: `tar -xf "$1"`
      - For `.zip`: `unzip "$1"`
      - For `.gz`: `gunzip "$1"`
      - For `.bz2`: `bunzip2 "$1"`
      - For `.xz`: `unxz "$1"`
      - Default: print "Unknown archive format" to stderr
  - Total: 3 functions (well within the 15-function limit)
  - ALL functions must use zsh-compatible syntax (no `read -p`)

  **Must NOT do**:
  - Do NOT add functions beyond compress, compress_zip, extract
  - Do NOT add aliases (compress/extract ARE the short names)
  - Do NOT handle `.rar` or `.7z` (would need extra packages)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file, ~30 lines, straightforward shell functions
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:
  - Omarchy's `default/bash/fns/compression` — Source: `compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }` and `alias decompress="tar -xzf"`. We expand this into a smarter `extract()` that handles multiple formats.
  - `modules/home-manager/cli/zsh/scripts/quote.sh` — Existing pattern for script files in this directory
  - `modules/home-manager/cli/zsh/zsh.nix:63-67` — How existing scripts are sourced via `xdg.configFile`

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Functions parse without errors in zsh
    Tool: Bash
    Preconditions: File created
    Steps:
      1. Run: zsh -n modules/home-manager/cli/zsh/scripts/compression.zsh
      2. Verify exit code 0
    Expected Result: No syntax errors
    Failure Indicators: Parse error
    Evidence: .sisyphus/evidence/task-3-zsh-parse.txt

  Scenario: Functions don't use bash-only syntax
    Tool: Bash
    Preconditions: File created
    Steps:
      1. Run: grep -n 'read -p' modules/home-manager/cli/zsh/scripts/compression.zsh
      2. Verify: no matches (exit code 1)
    Expected Result: No bash-only read calls found
    Failure Indicators: grep finds matches
    Evidence: .sisyphus/evidence/task-3-bash-compat.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Files: `modules/home-manager/cli/zsh/scripts/compression.zsh`

---

- [x] 4. Create ssh-forwarding.zsh shell function file

  **What to do**:
  - Create `modules/home-manager/cli/zsh/scripts/ssh-forwarding.zsh` with these functions:
    - `fip()` — Forward local ports to remote host. Usage: `fip <host> <port1> [port2] ...`
      - For each port: `ssh -fNL ${port}:localhost:${port} ${host}`
      - Print confirmation: "Forwarding port $port to $host"
    - `dip()` — Disconnect port forwards. Usage: `dip <port1> [port2] ...`
      - For each port: find and kill the SSH process via `lsof -ti:${port} | xargs kill 2>/dev/null`
      - Print confirmation: "Disconnected port $port"
    - `lip()` — List active SSH port forwards
      - `ps aux | grep 'ssh -fN' | grep -v grep`
  - Total: 3 functions
  - All arguments are positional — no hardcoded hosts or ports

  **Must NOT do**:
  - Do NOT hardcode any homelab IPs (10.10.x.x)
  - Do NOT add reverse tunnel functions (out of scope)
  - Do NOT use bash-only syntax

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file, ~25 lines, clear specification
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 5, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:
  - Omarchy's `default/bash/fns/ssh-port-forwarding` — Source pattern: `fip` forwards, `dip` disconnects, `lip` lists. Adapted for zsh compatibility.
  - `modules/home-manager/cli/zsh/zsh.nix:41-60` — oh-my-zsh plugins include `ssh` plugin. Verify `fip`, `dip`, `lip` don't conflict: these are custom names not defined by the oh-my-zsh ssh plugin (which only adds `ssh-add` helpers).

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Functions parse without errors in zsh
    Tool: Bash
    Preconditions: File created
    Steps:
      1. Run: zsh -n modules/home-manager/cli/zsh/scripts/ssh-forwarding.zsh
      2. Verify exit code 0
    Expected Result: No syntax errors
    Failure Indicators: Parse error
    Evidence: .sisyphus/evidence/task-4-zsh-parse.txt

  Scenario: No bash-only syntax present
    Tool: Bash
    Preconditions: File created
    Steps:
      1. Run: grep -n 'read -p' modules/home-manager/cli/zsh/scripts/ssh-forwarding.zsh
      2. Verify: no matches
    Expected Result: No bash-only read calls
    Evidence: .sisyphus/evidence/task-4-bash-compat.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Files: `modules/home-manager/cli/zsh/scripts/ssh-forwarding.zsh`

---

- [x] 5. Create git-worktrees.zsh shell function file

  **What to do**:
  - Create `modules/home-manager/cli/zsh/scripts/git-worktrees.zsh` with these functions:
    - `gwt()` — Create a new git worktree. Usage: `gwt [branch-name]`
      - If no arg: print usage and return 1
      - Run: `git worktree add ../${branch-name} -b ${branch-name}` (creates worktree in sibling directory)
      - Print: "Created worktree at ../${branch-name}"
      - `cd` into the new worktree directory
    - `gwtd()` — Delete a git worktree. Usage: `gwtd [branch-name]`
      - Use `gum confirm "Delete worktree ${branch-name}?"` for safety
      - If confirmed: `git worktree remove ../${branch-name}` then `git branch -d ${branch-name}`
      - If not confirmed: print "Cancelled" and return
    - `gwtl()` — List git worktrees
      - Simply: `git worktree list`
  - Total: 3 functions
  - CRITICAL: Function names use `gwt` prefix — NOT `ga` (taken: `git add`), NOT `gd` (taken: `git diff`), NOT `gw` (too short, easy to mis-trigger)

  **Must NOT do**:
  - Do NOT name any function `ga`, `gd`, `gb`, `gc`, `gm`, `gf`, `g`, `lg` — all taken by existing git aliases
  - Do NOT use `read -p` — use `gum confirm` for interactive prompts
  - Do NOT add stash/unstash logic — keep it simple

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file, ~30 lines, uses gum for TUI
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 4, 6)
  - **Blocks**: Task 7
  - **Blocked By**: None

  **References**:
  - Omarchy's `default/bash/fns/worktrees` — Source: `ga [branch]` creates worktree, `gd` removes with `gum confirm`. We rename to `gwt`/`gwtd` to avoid alias conflicts.
  - `modules/home-manager/cli/git.nix:54-78` — Existing git aliases. ALL of these names are OFF LIMITS for function names. Key conflicts: `ga` (git add), `gd` (git diff), `gb` (git branch), `gc` (git commit), `gm` (git merge), `gf` (git fetch).
  - `gum` package — Added by Task 1. Provides `gum confirm`, `gum input`, `gum choose` for TUI prompts.

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Functions parse without errors in zsh
    Tool: Bash
    Preconditions: File created
    Steps:
      1. Run: zsh -n modules/home-manager/cli/zsh/scripts/git-worktrees.zsh
      2. Verify exit code 0
    Expected Result: No syntax errors
    Evidence: .sisyphus/evidence/task-5-zsh-parse.txt

  Scenario: No alias name conflicts
    Tool: Bash
    Preconditions: File created
    Steps:
      1. Run: grep -E '^(ga|gd|gb|gc|gm|gf|g|lg)\(' modules/home-manager/cli/zsh/scripts/git-worktrees.zsh
      2. Verify: no matches (exit code 1)
    Expected Result: No conflicting function names
    Failure Indicators: grep finds function definitions using reserved names
    Evidence: .sisyphus/evidence/task-5-alias-conflicts.txt

  Scenario: Uses gum for confirmation (not read -p)
    Tool: Bash
    Preconditions: File created
    Steps:
      1. Run: grep -c 'gum confirm' modules/home-manager/cli/zsh/scripts/git-worktrees.zsh
      2. Verify: at least 1 match
      3. Run: grep -c 'read -p' modules/home-manager/cli/zsh/scripts/git-worktrees.zsh
      4. Verify: 0 matches
    Expected Result: Uses gum, not bash read
    Evidence: .sisyphus/evidence/task-5-gum-usage.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Files: `modules/home-manager/cli/zsh/scripts/git-worktrees.zsh`

---

- [x] 6. Create advanced screenshot script

  **What to do**:
  - Create `modules/home-manager/desktop/hyprland/scripts/screenshot.sh` with:
  - **Modes** (via argument):
    - `--region` (default, no arg): Use `slurp -d` for region selection, capture with `grim -g`
    - `--window`: Get active window geometry from `hyprctl activewindow -j`, capture with `grim -g`
    - `--fullscreen`: Get active monitor from `hyprctl activeworkspace -j`, then `hyprctl monitors -j` to find output name, capture with `grim -o`
    - `--edit`: Same as `--region` but opens result directly in satty
  - **Core flow** (all modes):
    1. `mkdir -p "$HOME/Pictures/screenshots"`
    2. Generate filename: `screenshot-$(date '+%Y%m%d-%H%M%S').png`
    3. Capture to file using grim
    4. Copy to clipboard: `wl-copy < "$filepath"` (separate step, NOT piped — avoids race condition if slurp cancelled)
    5. Show notification: `notify-send "Screenshot" "Saved and copied to clipboard" --icon "$filepath"`
    6. Background action handler: `(ACTION=$(notify-send "Screenshot" "Saved to $filename" --action "edit=Edit in Satty" --wait); [ "$ACTION" = "edit" ] && satty --filename "$filepath" --fullscreen --output-filename "$HOME/Pictures/screenshots/satty-$(date '+%Y%m%d-%H%M%S').png") &`
  - **Rotation handling** (for station's DP-2):
    - After getting geometry from `hyprctl activewindow -j` or monitors, check `transform` field
    - If transform is 3 (270°): swap width and height in the grim geometry
    - Use `hyprctl monitors -j | jq` to get the active monitor's transform value
    - Only relevant for `--window` and `--fullscreen` modes (slurp handles rotation itself in `--region`)
  - **Error handling**:
    - If slurp exits non-zero (user pressed Escape): exit silently, no notification
    - If grim fails: `notify-send "Screenshot" "Capture failed" --urgency critical`

  **Must NOT do**:
  - Do NOT support timer/delay mode
  - Do NOT support transforms other than 0 (normal) and 3 (270°) — no other host uses other transforms
  - Do NOT add clipboard history integration
  - Do NOT add OCR/text recognition features
  - Do NOT add multiple notification actions — only "Edit in Satty"

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Most complex task — ~80 lines of shell, rotation math, multiple modes, error handling
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 4, 5)
  - **Blocks**: Task 9
  - **Blocked By**: None

  **References**:
  - Omarchy's `bin/omarchy-cmd-screenshot` — Source pattern for smart mode detection, display transform handling, satty integration. Key logic to adapt: geometry calculation from `hyprctl activewindow -j` fields (`at` and `size`), monitor transform detection via `hyprctl monitors -j`.
  - `modules/home-manager/desktop/hyprland/packages.nix:52-56` — Confirms all screenshot deps are already installed: `grim`, `slurp`, `satty`, `libnotify` (notify-send)
  - `modules/home-manager/desktop/hyprland/packages.nix:77` — `wl-clipboard` already installed
  - `modules/home-manager/desktop/hyprland/packages.nix:85-88` — Pattern for placing scripts via `xdg.configFile` with `executable = true` (same as `random-wallpaper.sh`)
  - `hosts/station/default.nix:211` — Station's rotated monitor: `monitor = DP-2, 2560x1440@59.95, 0x0, 1, transform, 3` (270° rotation). Script must handle this.
  - `modules/home-manager/desktop/hyprland/keybindings.nix:36-38` — Current screenshot one-liners being replaced. Study current behavior to ensure feature parity.

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Script is syntactically valid
    Tool: Bash
    Preconditions: Script file created
    Steps:
      1. Run: bash -n modules/home-manager/desktop/hyprland/scripts/screenshot.sh
      2. Run: shellcheck modules/home-manager/desktop/hyprland/scripts/screenshot.sh
      3. Verify both exit code 0
    Expected Result: No syntax errors, shellcheck clean
    Failure Indicators: Parse error or shellcheck warning
    Evidence: .sisyphus/evidence/task-6-shellcheck.txt

  Scenario: Script handles all 4 modes as arguments
    Tool: Bash
    Preconditions: Script created
    Steps:
      1. Run: grep -c '\-\-region\|\-\-window\|\-\-fullscreen\|\-\-edit' modules/home-manager/desktop/hyprland/scripts/screenshot.sh
      2. Verify: at least 4 matches (all modes referenced)
    Expected Result: All 4 modes handled in the script
    Evidence: .sisyphus/evidence/task-6-modes.txt

  Scenario: Script handles rotation (transform 3)
    Tool: Bash
    Preconditions: Script created
    Steps:
      1. Run: grep -c 'transform' modules/home-manager/desktop/hyprland/scripts/screenshot.sh
      2. Verify: at least 1 match (rotation handling exists)
    Expected Result: Transform/rotation logic present
    Evidence: .sisyphus/evidence/task-6-rotation.txt

  Scenario: Script does NOT pipe grim through tee to wl-copy (race condition prevention)
    Tool: Bash
    Preconditions: Script created
    Steps:
      1. Run: grep -c 'tee.*wl-copy\|grim.*|.*wl-copy' modules/home-manager/desktop/hyprland/scripts/screenshot.sh
      2. Verify: 0 matches
    Expected Result: No piped grim-to-wl-copy (captures to file first, then copies)
    Evidence: .sisyphus/evidence/task-6-no-pipe.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Files: `modules/home-manager/desktop/hyprland/scripts/screenshot.sh`

---

- [x] 7. Wire shell functions into zsh.nix

  **What to do**:
  - Edit `modules/home-manager/cli/zsh/zsh.nix` to source the 3 new function files:
    - Add `xdg.configFile` entries for each function file (following the `quote.sh` pattern at lines 63-67):
      ```nix
      xdg.configFile."zsh/scripts/compression.zsh" = {
        source = ./scripts/compression.zsh;
        executable = true;
      };
      xdg.configFile."zsh/scripts/ssh-forwarding.zsh" = {
        source = ./scripts/ssh-forwarding.zsh;
        executable = true;
      };
      xdg.configFile."zsh/scripts/git-worktrees.zsh" = {
        source = ./scripts/git-worktrees.zsh;
        executable = true;
      };
      ```
    - Add source lines to `initContent` (after the existing content, before the closing `''`):
      ```bash
      # Omarchy-inspired shell function libraries
      [[ -f "$HOME/.config/zsh/scripts/compression.zsh" ]] && source "$HOME/.config/zsh/scripts/compression.zsh"
      [[ -f "$HOME/.config/zsh/scripts/ssh-forwarding.zsh" ]] && source "$HOME/.config/zsh/scripts/ssh-forwarding.zsh"
      [[ -f "$HOME/.config/zsh/scripts/git-worktrees.zsh" ]] && source "$HOME/.config/zsh/scripts/git-worktrees.zsh"
      ```

  **Must NOT do**:
  - Do NOT inline the function code in initContent
  - Do NOT change any existing initContent code
  - Do NOT remove or modify the existing quote.sh sourcing

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small edit to existing file, adding ~12 lines following established pattern
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 8, 9)
  - **Blocks**: F1-F4
  - **Blocked By**: Tasks 1, 3, 4, 5

  **References**:
  - `modules/home-manager/cli/zsh/zsh.nix:63-67` — EXACT pattern to follow for `xdg.configFile` entries. Copy this pattern for the 3 new files.
  - `modules/home-manager/cli/zsh/zsh.nix:17-37` — Existing `initContent` block. New source lines go at the END, before the closing `''` on line 37.
  - `modules/home-manager/cli/zsh/scripts/` — Directory where Tasks 3, 4, 5 placed the function files

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Nix evaluation succeeds with new source entries
    Tool: Bash
    Preconditions: zsh.nix edited, function files exist
    Steps:
      1. Run: nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
      2. Verify exit code 0
    Expected Result: Nix evaluation succeeds
    Failure Indicators: Nix evaluation error about missing file or syntax
    Evidence: .sisyphus/evidence/task-7-nix-eval.txt

  Scenario: Source lines are guarded with file existence check
    Tool: Bash
    Preconditions: zsh.nix edited
    Steps:
      1. Run: grep -c '\[\[ -f.*\.zsh.*\]\] && source' modules/home-manager/cli/zsh/zsh.nix
      2. Verify: 3 matches (one per function file)
    Expected Result: All 3 function files sourced with guards
    Evidence: .sisyphus/evidence/task-7-source-guards.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Files: `modules/home-manager/cli/zsh/zsh.nix`

---

- [x] 8. Create web-apps.nix module with desktop entries

  **What to do**:
  - Create `modules/home-manager/misc/web-apps.nix` as a new NixOS module:
    - Add `options.web-apps.enable = lib.mkEnableOption "Web app launchers"` 
    - In `config = lib.mkIf cfg.enable`:
      1. Package the `launch-or-focus` script (from Task 2) via `pkgs.writeShellScriptBin "launch-or-focus"` and add to `home.packages`
      2. Create 7 `xdg.desktopEntries` — one per web app:
        - `webapp-github` — Name: "GitHub", Exec: `launch-or-focus chrome-github https://github.com`, using `chromium --app=https://github.com` as the launch command
        - `webapp-youtube` — Name: "YouTube", Exec with `chromium --app=https://youtube.com`
        - `webapp-claude` — Name: "Claude", Exec with `chromium --app=https://claude.ai`
        - `webapp-protonmail` — Name: "ProtonMail", Exec with `chromium --app=https://mail.proton.me`
        - `webapp-homeassistant` — Name: "Home Assistant", Exec with `chromium --app=https://homeassistant.pytt.io`
        - `webapp-tradingview` — Name: "TradingView", Exec with `chromium --app=https://tradingview.com/chart/EWLeEGVs/`
        - `webapp-element` — Name: "Element", Exec with `chromium --app=https://element.pytt.io`
      3. Each desktop entry must have:
        - `type = "Application"`
        - `terminal = false`
        - `icon = "chromium"` (no custom icons — out of scope)
        - `categories = ["Network" "WebBrowser"]`
        - NO `mimeType` field (Zen Browser owns URL handlers)
      4. The `Exec` field pattern for each entry:
        - `launch-or-focus chrome-<domain> "chromium --app=<url>"`
        - The window pattern uses `chrome-<domain>` which is how Chromium names --app windows
      5. Add a TEMPLATE comment block at the bottom of the file showing how to add more web apps:
        ```nix
        # --- TEMPLATE: Add new web apps ---
        # Copy this block and customize:
        #   webapp-NAME = {
        #     name = "Display Name";
        #     exec = ''launch-or-focus chrome-DOMAIN "chromium --app=https://DOMAIN"'';
        #     icon = "chromium";
        #     type = "Application";
        #     terminal = false;
        #     categories = ["Network" "WebBrowser"];
        #   };
        ```
  - Update `modules/home-manager/misc/default.nix` to import `./web-apps.nix`
  - Enable in `profiles/desktop.nix` by adding `web-apps.enable = true;`

  **Must NOT do**:
  - Do NOT set `mimeType` on ANY desktop entry
  - Do NOT add per-app enable toggles — single `web-apps.enable` for all
  - Do NOT fetch/manage icons — use `icon = "chromium"` for all
  - Do NOT use `google-chrome` binary — only `chromium`
  - Do NOT add Hyprland keybindings for web apps (rofi-only launch)
  - Do NOT create workspace assignment rules

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: New module with multiple desktop entries, script packaging, template documentation. Touches 3 files.
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7, 9)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 2

  **References**:
  - `modules/home-manager/misc/scripts/launch-or-focus.sh` (Task 2 output) — The script to package via `writeShellScriptBin`
  - `modules/home-manager/misc/chromium.nix` — Module pattern to follow: `options.X.enable = lib.mkEnableOption`, `config = lib.mkIf`, `config.home-manager.users.${config.user}`
  - `modules/home-manager/misc/default.nix` — Current imports: `thunar.nix`, `chromium.nix`, `zen-browser.nix`. Add `./web-apps.nix` to this list.
  - `modules/home-manager/misc/zen-browser.nix:36-57` — Existing `.desktop` entry pattern via `xdg.desktopEntries`. Study the structure for consistent formatting.
  - `modules/home-manager/desktop/hyprland/default.nix:143` — Window rule `match:class ^(chrome-.*)` already applies borderless to Chromium --app windows. No additional rules needed.
  - `profiles/desktop.nix` — Where to add `web-apps.enable = true` alongside other module enables (e.g., `chromium.enable = true` is likely here)
  - Omarchy's `bin/omarchy-launch-webapp` and `bin/omarchy-launch-or-focus-webapp` — Architecture reference for the launch pattern

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Nix evaluation succeeds with new module
    Tool: Bash
    Preconditions: web-apps.nix created, default.nix updated, desktop.nix updated
    Steps:
      1. Run: nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
      2. Verify exit code 0
    Expected Result: Nix evaluation succeeds for laptop
    Failure Indicators: Missing import, undefined variable, syntax error
    Evidence: .sisyphus/evidence/task-8-nix-eval.txt

  Scenario: All 7 desktop entries are defined
    Tool: Bash
    Preconditions: web-apps.nix created
    Steps:
      1. Run: grep -c 'webapp-' modules/home-manager/misc/web-apps.nix
      2. Verify: at least 7 matches (7 desktop entries)
    Expected Result: 7 web app entries defined
    Evidence: .sisyphus/evidence/task-8-entry-count.txt

  Scenario: No mimeType fields present
    Tool: Bash
    Preconditions: web-apps.nix created
    Steps:
      1. Run: grep -ci 'mimetype\|mimeType' modules/home-manager/misc/web-apps.nix
      2. Verify: 0 matches
    Expected Result: No MIME type contamination
    Evidence: .sisyphus/evidence/task-8-no-mime.txt

  Scenario: All entries use chromium binary (not google-chrome)
    Tool: Bash
    Preconditions: web-apps.nix created
    Steps:
      1. Run: grep -c 'google-chrome' modules/home-manager/misc/web-apps.nix
      2. Verify: 0 matches
      3. Run: grep -c 'chromium --app' modules/home-manager/misc/web-apps.nix
      4. Verify: at least 7 matches
    Expected Result: All entries use chromium
    Evidence: .sisyphus/evidence/task-8-chromium-binary.txt

  Scenario: Template comment exists for adding new web apps
    Tool: Bash
    Preconditions: web-apps.nix created
    Steps:
      1. Run: grep -c 'TEMPLATE' modules/home-manager/misc/web-apps.nix
      2. Verify: at least 1 match
    Expected Result: Template documentation present
    Evidence: .sisyphus/evidence/task-8-template.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Files: `modules/home-manager/misc/web-apps.nix`, `modules/home-manager/misc/default.nix`, `profiles/desktop.nix`

---

- [x] 9. Convert keybindings to bindd + replace screenshot shortcuts

  **What to do**:
  - Edit `modules/home-manager/desktop/hyprland/keybindings.nix` to:

  **Part A — Convert all binding types to descriptive variants:**
  - `bind` → `bindd` (52 entries, lines 30-110)
  - `bindm` → `binddm` (2 entries, lines 8-11)
  - `bindel` → `binddel` (4 entries, lines 14-19)
  - `bindl` → `binddl` (4 entries, lines 22-27)
  - For each entry, insert a 2-5 word description between the KEY and DISPATCHER fields
  - Format: `"MODS, KEY, Description, dispatcher, args"`
  - Example transformations:
    - `"$mainMod, Q, killactive,"` → `"$mainMod, Q, Kill active window, killactive,"`
    - `"$mainMod, H, movefocus, l"` → `"$mainMod, H, Focus window left, movefocus, l"`
    - `"$mainMod, 1, workspace, 1"` → `"$mainMod, 1, Workspace 1, workspace, 1"`
    - `"$mainMod, T, exec, pypr toggle term"` → `"$mainMod, T, Toggle terminal scratchpad, exec, pypr toggle term"`
    - `", XF86AudioRaiseVolume, exec, ..."` → `", XF86AudioRaiseVolume, Volume up, exec, ..."`
  - Scratchpad descriptions must be human-readable (from pyprland.toml context):
    - `term` → "Toggle dropdown terminal"
    - `notes` → "Toggle Obsidian notes"
    - `todo` → "Toggle Planify tasks"
    - `scratch` → "Toggle scratch editor"
    - `daily` → "Toggle daily journal"
    - `vault` → "Toggle main vault"
    - `cheatsheet-search` → "Toggle cheatsheet viewer"
  - CRITICAL: No commas in descriptions (would corrupt Hyprland parser)
  - CRITICAL: Preserve exact Nix string escaping on `''`-delimited lines (lines 23-24, 36-38)

  **Part B — Replace screenshot keybindings:**
  - Remove the 2 existing inline screenshot commands (lines 36-38)
  - Replace with 3 new bindings using the screenshot.sh script (from Task 6):
    - `"$mainMod, Print, Region screenshot, exec, ~/.config/hypr/screenshot.sh --region"` (default region mode)
    - `"$mainMod SHIFT, Print, Window screenshot, exec, ~/.config/hypr/screenshot.sh --window"` (active window)
    - `"$mainMod CTRL, Print, Fullscreen screenshot, exec, ~/.config/hypr/screenshot.sh --fullscreen"` (current output)
    - `"$mainMod ALT, Print, Screenshot with editor, exec, ~/.config/hypr/screenshot.sh --edit"` (region + satty)
    - Also keep backward-compatible binding: `''ALT CTRL, S, Quick screenshot to clipboard, exec, ~/.config/hypr/screenshot.sh --region''` (matches old muscle memory)

  **Part C — Register screenshot script in packages.nix:**
  - Add `xdg.configFile` entry for `screenshot.sh` in `packages.nix` (alongside `random-wallpaper.sh`):
    ```nix
    "hypr/screenshot.sh" = {
      source = ./scripts/screenshot.sh;
      executable = true;
    };
    ```

  **Must NOT do**:
  - Do NOT change ANY dispatcher or argument — ONLY add descriptions and change bind type
  - Do NOT reorganize, reorder, or regroup bindings
  - Do NOT remove comment lines
  - Do NOT add descriptions longer than 5 words
  - Do NOT use commas in any description string
  - Do NOT add Hyprland submap/leader-key features

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: High-precision text transformation across 62 bindings, must preserve exact Nix escaping, touches 2 files
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7, 8)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 6

  **References**:
  - `modules/home-manager/desktop/hyprland/keybindings.nix` — The file being transformed. Read EVERY line carefully. Pay special attention to `''`-delimited strings at lines 23-24 and 36-38.
  - `modules/home-manager/desktop/hyprland/packages.nix:85-88` — Pattern for `xdg.configFile` script registration (random-wallpaper.sh). Add screenshot.sh entry in the same section.
  - `modules/home-manager/desktop/hyprland/scripts/screenshot.sh` (Task 6 output) — The script being referenced in new keybindings
  - Omarchy's `config/hypr/bindings.conf` — Reference for `bindd` format and description style. Key pattern: `bindd = MODS, KEY, Description, dispatcher, args`. Descriptions are 2-4 words.
  - `modules/home-manager/desktop/hyprland/config/pyprland.toml` — Maps scratchpad names to their actual content (needed for meaningful descriptions): `term`=kitty+tmux, `notes`=obsidian, `todo`=planify, `scratch`=nvim scratchpad, `daily`=nvim daily note, `vault`=nvim vault, `cheatsheet-search`=vimiv
  - Hyprland wiki on `bindd`: The `d` flag is freely combinable with other flags. `bind` → `bindd`, `bindm` → `binddm`, `bindel` → `binddel`, `bindl` → `binddl`.

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Nix evaluation succeeds after conversion
    Tool: Bash
    Preconditions: keybindings.nix edited, packages.nix edited
    Steps:
      1. Run: nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
      2. Verify exit code 0
    Expected Result: Nix evaluation succeeds
    Failure Indicators: Nix syntax error, missing attribute
    Evidence: .sisyphus/evidence/task-9-nix-eval.txt

  Scenario: No plain bind/bindm/bindel/bindl remain (all converted to d variants)
    Tool: Bash
    Preconditions: keybindings.nix edited
    Steps:
      1. Run: grep -E '^\s*(bind|bindm|bindel|bindl)\s*=' modules/home-manager/desktop/hyprland/keybindings.nix
      2. Verify: 0 matches (all should be bindd/binddm/binddel/binddl now)
    Expected Result: No unconverted binding types
    Failure Indicators: grep finds old bind types
    Evidence: .sisyphus/evidence/task-9-no-old-binds.txt

  Scenario: All new binding types present
    Tool: Bash
    Preconditions: keybindings.nix edited
    Steps:
      1. Run: grep -c 'bindd\s*=' modules/home-manager/desktop/hyprland/keybindings.nix
      2. Verify: at least 1 match
      3. Run: grep -c 'binddm\s*=' modules/home-manager/desktop/hyprland/keybindings.nix
      4. Verify: at least 1 match
      5. Run: grep -c 'binddel\s*=' modules/home-manager/desktop/hyprland/keybindings.nix
      6. Verify: at least 1 match
      7. Run: grep -c 'binddl\s*=' modules/home-manager/desktop/hyprland/keybindings.nix
      8. Verify: at least 1 match
    Expected Result: All 4 binding types converted
    Evidence: .sisyphus/evidence/task-9-binding-types.txt

  Scenario: No commas in description fields
    Tool: Bash
    Preconditions: keybindings.nix edited
    Steps:
      1. For each bindd line, extract the description field (3rd comma-separated value)
      2. This is complex to grep — instead verify no line has more comma-separated fields than expected
      3. Run: nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath (Nix eval catches most issues)
    Expected Result: Nix evaluation passes (corrupt descriptions would cause Hyprland parse errors at runtime, but Nix eval catches syntax issues)
    Evidence: .sisyphus/evidence/task-9-nix-eval.txt (reuses eval evidence)

  Scenario: Screenshot script registered in packages.nix
    Tool: Bash
    Preconditions: packages.nix edited
    Steps:
      1. Run: grep -c 'screenshot.sh' modules/home-manager/desktop/hyprland/packages.nix
      2. Verify: at least 1 match
    Expected Result: Screenshot script registered as xdg.configFile
    Evidence: .sisyphus/evidence/task-9-screenshot-registered.txt

  Scenario: Old inline screenshot commands removed
    Tool: Bash
    Preconditions: keybindings.nix edited
    Steps:
      1. Run: grep -c 'grim -g.*slurp' modules/home-manager/desktop/hyprland/keybindings.nix
      2. Verify: 0 matches (old inline commands removed)
    Expected Result: No inline grim commands in keybindings
    Evidence: .sisyphus/evidence/task-9-no-inline-screenshots.txt
  ```

  **Commit**: YES (groups with Wave 2 commit)
  - Message: `feat(desktop): add Omarchy-inspired gems — web apps, bindd, shell functions, screenshot`
  - Files: `modules/home-manager/desktop/hyprland/keybindings.nix`, `modules/home-manager/desktop/hyprland/packages.nix`
  - Pre-commit: `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, check content). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `nix flake check` and verify `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` evaluates. Review all changed files for: hardcoded paths, bash-only syntax in zsh files, missing Nix escaping, unused imports, AI slop (excessive comments, over-abstraction). Verify all scripts are ShellCheck-clean.
  Output: `Eval [PASS/FAIL] | ShellCheck [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration (web app launches via rofi, screenshot bindings work, shell functions load). Test edge cases: web app with existing window, screenshot on rotated display (station only). Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Detect cross-task contamination. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| Commit | Message | Files | Pre-commit Check |
|--------|---------|-------|-----------------|
| After Wave 2 | `feat(desktop): add Omarchy-inspired gems — web apps, bindd, shell functions, screenshot` | All changed files | `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` |

---

## Success Criteria

### Verification Commands
```bash
# Nix evaluation succeeds
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
# Expected: /nix/store/...-nixos-system-laptop-...

# After rebuild — bindings are discoverable
hyprctl binds -j | jq '[.[] | select(.has_description == true)] | length'
# Expected: 62+ (all bindings have descriptions)

# Shell functions defined
zsh -ic 'type compress'   # Expected: "compress is a shell function"
zsh -ic 'type fip'        # Expected: "fip is a shell function"
zsh -ic 'type gwt'        # Expected: "gwt is a shell function"

# Web app desktop entries exist
ls ~/.local/share/applications/webapp-*.desktop | wc -l
# Expected: 7

# Screenshot script executable
ls -la ~/.config/hypr/screenshot.sh
# Expected: -rwx... (executable)

# No alias conflicts
zsh -ic 'type ga'   # Expected: still "ga is an alias for git add"
zsh -ic 'type gd'   # Expected: still "gd is an alias for git diff"
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] `nix eval` passes for all 3 desktop hosts
- [ ] `just rebuild` succeeds
