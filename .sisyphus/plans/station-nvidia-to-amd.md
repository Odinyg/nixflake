# Station: NVIDIA → AMD GPU Swap

## TL;DR

> **Quick Summary**: Swap station's NVIDIA GPU for AMD RX 6700 XT — remove all NVIDIA config, enable existing AMD module (trimmed), disable AI services (Ollama, LM Studio, Open WebUI), and relocate shared NVIDIA workarounds to vnpc-21 host config.
> 
> **Deliverables**:
> - Station boots with AMD `amdgpu` driver, no NVIDIA remnants
> - AMD module trimmed of aggressive kernel params and unnecessary ROCm
> - AI services disabled on station (Ollama, LM Studio, Open WebUI)
> - vnpc-21 retains all NVIDIA workarounds via host-level overrides
> - Shared Hyprland/zen-browser configs are GPU-agnostic
> 
> **Estimated Effort**: Short
> **Parallel Execution**: YES — 2 waves
> **Critical Path**: Tasks 1-3 (parallel) → Task 4 (verify)

---

## Context

### Original Request
User is physically replacing the NVIDIA GPU in station with an AMD RX 6700 XT (RDNA 2). Also moving Ollama and LM Studio to another machine, so those should be disabled.

### Interview Summary
**Key Discussions**:
- AMD card: RX 6700 XT (RDNA 2) — fully supported by `amdgpu` kernel driver
- Ollama: disable entirely, moving to another PC
- LM Studio: remove from station
- Open WebUI: disable (depends on local Ollama which is going away)
- Hyprland NVIDIA workarounds: override per-host (move to vnpc-21, remove from shared)
- AMD module kernel params: trim aggressive settings, keep only `amd_pstate=active` + `amdgpu.dc=1`

**Research Findings**:
- AMD GPU module already exists at `modules/nixos/hardware/amd-gpu.nix`
- NVIDIA profile (`profiles/hardware/nvidia.nix`) must be kept for vnpc-21
- Gaming module is GPU-agnostic — no changes needed
- Station `hardware-configuration.nix` has no NVIDIA kernel modules — no changes needed

### Metis Review
**Identified Gaps** (addressed):
- Open WebUI depends on local Ollama → user chose to disable it too
- Zen-browser NVIDIA env vars are shared → must be moved to vnpc-21 (not optional)
- vnpc-21 uses user `odin` → home-manager path is `home-manager.users.odin`

---

## Work Objectives

### Core Objective
Replace NVIDIA GPU configuration with AMD on station, disable AI services, and ensure vnpc-21 retains its NVIDIA workarounds.

### Concrete Deliverables
- `hosts/station/default.nix` — AMD GPU enabled, NVIDIA removed, AI services disabled
- `modules/nixos/hardware/amd-gpu.nix` — trimmed kernel params, no ROCm
- `modules/home-manager/desktop/hyprland/default.nix` — GPU-agnostic (no NVIDIA settings)
- `modules/home-manager/misc/zen-browser.nix` — GPU-agnostic (no NVIDIA env vars)
- `hosts/vnpc-21/default.nix` — NVIDIA Hyprland + zen-browser overrides added

### Definition of Done
- [ ] `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` succeeds
- [ ] `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath` succeeds
- [ ] `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` succeeds
- [ ] Station has `amdgpu` videoDriver, no `nvidia` videoDriver
- [ ] vnpc-21 still has `nvidia` videoDriver

### Must Have
- Station uses `amdgpu` driver
- All NVIDIA references removed from station config
- Ollama, LM Studio, Open WebUI disabled on station
- vnpc-21 retains NVIDIA cursor/opengl workarounds
- vnpc-21 retains NVIDIA zen-browser env vars
- Shared Hyprland and zen-browser configs are GPU-neutral

### Must NOT Have (Guardrails)
- Do NOT modify `profiles/hardware/nvidia.nix` — vnpc-21 depends on it
- Do NOT modify `hosts/vnpc-21/hardware-configuration.nix` — its nvidia kernel modules are correct
- Do NOT modify `profiles/desktop.nix` or `profiles/base.nix`
- Do NOT modify the gaming module — it's already GPU-agnostic
- Do NOT refactor or parameterize the ollama module's `acceleration = "cuda"` — out of scope
- Do NOT touch station's `misc.vrr`, `render.direct_scanout`, `decoration.blur.enabled` Hyprland overrides
- Do NOT add VA-API packages, Vulkan tools, or GPU debug packages to the AMD module
- Do NOT add `amdgpu` to station's `hardware-configuration.nix` initrd modules — RDNA 2 auto-loads

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: N/A (NixOS config, not a software project)
- **Automated tests**: None — verification via `nix eval` assertions
- **Framework**: `nix eval` for config evaluation

### QA Policy
Every task includes `nix eval` verification commands. Evidence saved to `.sisyphus/evidence/`.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — all independent):
├── Task 1: Trim AMD GPU module [quick]
├── Task 2: Station host config — NVIDIA out, AMD in, AI off [quick]
└── Task 3: Relocate NVIDIA workarounds — shared→vnpc-21 [quick]

Wave FINAL (After Wave 1):
├── Task F1: Plan compliance audit [oracle]
├── Task F2: Code quality review [unspecified-high]
├── Task F3: Real manual QA — eval all hosts [unspecified-high]
└── Task F4: Scope fidelity check [deep]
-> Present results -> Get explicit user okay

Critical Path: Tasks 1-3 (parallel) → F1-F4 (parallel) → user okay
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | F1-F4 |
| 2 | — | F1-F4 |
| 3 | — | F1-F4 |
| F1-F4 | 1, 2, 3 | user okay |

### Agent Dispatch Summary

- **Wave 1**: **3** — T1 → `quick`, T2 → `quick`, T3 → `quick`
- **FINAL**: **4** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Trim AMD GPU module

  **What to do**:
  - Edit `modules/nixos/hardware/amd-gpu.nix`
  - Remove `rocmPackages.clr` from `hardware.graphics.extraPackages` (keep only `amdvlk`)
  - Replace kernel params with exactly: `["amd_pstate=active" "amdgpu.dc=1"]`
  - Remove `processor.max_cstate=1`, `idle=poll`, `mitigations=off`
  - Keep everything else (videoDrivers, graphics.enable, enable32Bit, extraPackages32)

  **Must NOT do**:
  - Do not add new packages
  - Do not change the option name or structure
  - Do not add PRIME support or other features

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file, ~3 line changes, straightforward removal
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: F1-F4
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/nixos/hardware/amd-gpu.nix` — the entire file (40 lines), modify in place

  **Acceptance Criteria**:

  ```
  Scenario: AMD module has correct kernel params
    Tool: Bash (nix eval)
    Steps:
      1. Run: nix eval --json '.#nixosConfigurations.station.config.boot.kernelParams'
      2. Assert output contains "amd_pstate=active"
      3. Assert output contains "amdgpu.dc=1"
      4. Assert output does NOT contain "mitigations=off"
      5. Assert output does NOT contain "idle=poll"
      6. Assert output does NOT contain "processor.max_cstate=1"
    Expected Result: Only safe AMD params present, aggressive params removed
    Evidence: .sisyphus/evidence/task-1-kernel-params.txt

  Scenario: AMD module has no ROCm packages
    Tool: Bash (grep)
    Steps:
      1. Run: grep -c "rocmPackages" modules/nixos/hardware/amd-gpu.nix
      2. Assert count is 0
    Expected Result: No rocmPackages references in the file
    Evidence: .sisyphus/evidence/task-1-no-rocm.txt
  ```

  **Commit**: YES (groups with Tasks 2, 3)
  - Message: `refactor(station): swap NVIDIA for AMD GPU and disable AI services`
  - Files: `modules/nixos/hardware/amd-gpu.nix`

- [x] 2. Station host config — NVIDIA out, AMD in, AI off

  **What to do**:
  - Edit `hosts/station/default.nix`
  - Remove the import line: `../../profiles/hardware/nvidia.nix`
  - Remove the entire `hardware.nvidia-gpu` block (lines 81-86):
    ```nix
    hardware.nvidia-gpu = {
      enable = true;
      driverPackage = "latest";
      open = false;
      prime.enable = false;
    };
    ```
  - Remove `environment.variables.__GL_VRR_ALLOWED = "0";` (line 88)
  - Remove the NVIDIA systemd service disables (lines 109-111):
    ```nix
    systemd.services.nvidia-suspend.enable = false;
    systemd.services.nvidia-hibernate.enable = false;
    systemd.services.nvidia-resume.enable = false;
    ```
  - Add `amd-gpu.enable = true;` in place of the NVIDIA GPU section (update the section comment from "HARDWARE - NVIDIA GPU" to "HARDWARE - AMD GPU")
  - Change `ollama.enable = true;` to `ollama.enable = false;` (or remove the line)
  - Change `lmstudio.enable = true;` to `lmstudio.enable = false;` (or remove the line)
  - Change `hosted-services.open-webui.enable = true;` to `hosted-services.open-webui.enable = false;` (or remove the line)

  **Must NOT do**:
  - Do not modify `hosts/station/hardware-configuration.nix`
  - Do not touch Hyprland overrides (`misc.vrr`, `render.direct_scanout`, `decoration.blur.enabled`, `general.gaps_in/gaps_out`)
  - Do not modify networking, users, boot, power management, or any other sections
  - Do not add new packages or features

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file, clear removals and substitutions, no logic changes
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: F1-F4
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `hosts/station/default.nix:9-14` — imports list (remove nvidia.nix from here)
  - `hosts/station/default.nix:79-86` — NVIDIA GPU section to replace with AMD
  - `hosts/station/default.nix:88` — `__GL_VRR_ALLOWED` env var to remove
  - `hosts/station/default.nix:108-111` — NVIDIA systemd service disables to remove
  - `hosts/station/default.nix:204` — `ollama.enable` to disable
  - `hosts/station/default.nix:205` — `lmstudio.enable` to disable
  - `hosts/station/default.nix:250` — `hosted-services.open-webui.enable` to disable

  **Acceptance Criteria**:

  ```
  Scenario: Station evals successfully with AMD driver
    Tool: Bash (nix eval)
    Steps:
      1. Run: nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath
      2. Assert: command exits 0 (no eval errors)
    Expected Result: Station config evaluates without errors
    Evidence: .sisyphus/evidence/task-2-station-eval.txt

  Scenario: Station has amdgpu videoDriver, not nvidia
    Tool: Bash (nix eval)
    Steps:
      1. Run: nix eval --json '.#nixosConfigurations.station.config.services.xserver.videoDrivers'
      2. Assert output is ["amdgpu"]
      3. Assert output does NOT contain "nvidia"
    Expected Result: Only amdgpu driver configured
    Evidence: .sisyphus/evidence/task-2-video-drivers.txt

  Scenario: AI services disabled on station
    Tool: Bash (nix eval)
    Steps:
      1. Run: nix eval '.#nixosConfigurations.station.config.services.ollama.enable'
      2. Assert output is "false"
      3. Run: nix eval '.#nixosConfigurations.station.config.services.open-webui.enable'
      4. Assert output is "false"
    Expected Result: Ollama and Open WebUI disabled
    Evidence: .sisyphus/evidence/task-2-ai-disabled.txt

  Scenario: No nvidia references remain in station config
    Tool: Bash (grep)
    Steps:
      1. Run: grep -i "nvidia" hosts/station/default.nix
      2. Assert: no matches (exit code 1)
    Expected Result: Zero nvidia references in station host config
    Evidence: .sisyphus/evidence/task-2-no-nvidia.txt
  ```

  **Commit**: YES (groups with Tasks 1, 3)
  - Message: `refactor(station): swap NVIDIA for AMD GPU and disable AI services`
  - Files: `hosts/station/default.nix`

- [x] 3. Relocate NVIDIA workarounds from shared configs to vnpc-21

  **What to do**:

  **Part A — Clean shared Hyprland config** (`modules/home-manager/desktop/hyprland/default.nix`):
  - Remove the NVIDIA cursor block (lines 98-102):
    ```nix
    # NVIDIA-specific cursor configuration
    cursor = {
      no_hardware_cursors = true;
      no_break_fs_vrr = true;
    };
    ```
  - Remove the NVIDIA opengl block (lines 104-107):
    ```nix
    # NVIDIA-specific OpenGL settings
    opengl = {
      nvidia_anti_flicker = true;
    };
    ```

  **Part B — Clean shared zen-browser config** (`modules/home-manager/misc/zen-browser.nix`):
  - Remove lines 23-25 from `home.sessionVariables`:
    ```nix
    # NVIDIA-specific settings
    MOZ_DISABLE_RDD_SANDBOX = "1";
    MOZ_X11_EGL = "1";
    ```
  - Keep: `MOZ_ENABLE_WAYLAND`, `MOZ_WAYLAND_USE_VAAPI`, `MOZ_USE_XINPUT2`

  **Part C — Add NVIDIA overrides to vnpc-21** (`hosts/vnpc-21/default.nix`):
  - Add Hyprland NVIDIA settings as host-level overrides (vnpc-21 user is `odin`):
    ```nix
    # NVIDIA-specific Hyprland workarounds
    home-manager.users.odin.wayland.windowManager.hyprland.settings = {
      cursor = {
        no_hardware_cursors = true;
        no_break_fs_vrr = true;
      };
      opengl = {
        nvidia_anti_flicker = true;
      };
    };
    ```
  - Add zen-browser NVIDIA env vars:
    ```nix
    # NVIDIA-specific browser environment variables
    home-manager.users.odin.home.sessionVariables = {
      MOZ_DISABLE_RDD_SANDBOX = "1";
      MOZ_X11_EGL = "1";
    };
    ```
  - Place these in the "HOST-SPECIFIC OVERRIDES" section, following the existing pattern

  **Must NOT do**:
  - Do not modify `profiles/hardware/nvidia.nix`
  - Do not modify `hosts/vnpc-21/hardware-configuration.nix`
  - Do not remove `MOZ_ENABLE_WAYLAND`, `MOZ_WAYLAND_USE_VAAPI`, or `MOZ_USE_XINPUT2` from shared zen-browser config
  - Do not add/remove any other Hyprland settings

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Three files, clear move operation (remove from A+B, add to C), no logic changes
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: F1-F4
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/home-manager/desktop/hyprland/default.nix:98-107` — NVIDIA cursor/opengl blocks to remove
  - `modules/home-manager/misc/zen-browser.nix:23-25` — NVIDIA env vars to remove
  - `hosts/vnpc-21/default.nix:188-194` — existing home-manager override pattern (uses `home-manager.users.odin.services.hypridle.settings`)
  - `hosts/vnpc-21/default.nix:268-279` — existing home-manager override pattern (uses `home-manager.users.odin.programs.git.ignores`)

  **Acceptance Criteria**:

  ```
  Scenario: Shared Hyprland config has no NVIDIA settings
    Tool: Bash (grep)
    Steps:
      1. Run: grep -i "nvidia" modules/home-manager/desktop/hyprland/default.nix
      2. Assert: no matches (exit code 1)
      3. Run: grep "no_hardware_cursors" modules/home-manager/desktop/hyprland/default.nix
      4. Assert: no matches (exit code 1)
    Expected Result: Zero NVIDIA references in shared Hyprland config
    Evidence: .sisyphus/evidence/task-3-hyprland-clean.txt

  Scenario: Shared zen-browser has no NVIDIA env vars
    Tool: Bash (grep)
    Steps:
      1. Run: grep "MOZ_DISABLE_RDD_SANDBOX" modules/home-manager/misc/zen-browser.nix
      2. Assert: no matches (exit code 1)
      3. Run: grep "MOZ_X11_EGL" modules/home-manager/misc/zen-browser.nix
      4. Assert: no matches (exit code 1)
      5. Run: grep "MOZ_ENABLE_WAYLAND" modules/home-manager/misc/zen-browser.nix
      6. Assert: match found (this one stays)
    Expected Result: NVIDIA vars removed, Wayland vars remain
    Evidence: .sisyphus/evidence/task-3-zen-clean.txt

  Scenario: vnpc-21 has NVIDIA Hyprland overrides
    Tool: Bash (grep)
    Steps:
      1. Run: grep "no_hardware_cursors" hosts/vnpc-21/default.nix
      2. Assert: match found
      3. Run: grep "nvidia_anti_flicker" hosts/vnpc-21/default.nix
      4. Assert: match found
    Expected Result: NVIDIA Hyprland workarounds present in vnpc-21 host config
    Evidence: .sisyphus/evidence/task-3-vnpc21-hyprland.txt

  Scenario: vnpc-21 has NVIDIA zen-browser env vars
    Tool: Bash (grep)
    Steps:
      1. Run: grep "MOZ_DISABLE_RDD_SANDBOX" hosts/vnpc-21/default.nix
      2. Assert: match found
      3. Run: grep "MOZ_X11_EGL" hosts/vnpc-21/default.nix
      4. Assert: match found
    Expected Result: NVIDIA browser vars present in vnpc-21 host config
    Evidence: .sisyphus/evidence/task-3-vnpc21-zen.txt

  Scenario: vnpc-21 evals successfully
    Tool: Bash (nix eval)
    Steps:
      1. Run: nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath
      2. Assert: command exits 0
    Expected Result: vnpc-21 config evaluates without errors
    Evidence: .sisyphus/evidence/task-3-vnpc21-eval.txt

  Scenario: laptop evals successfully (no regression)
    Tool: Bash (nix eval)
    Steps:
      1. Run: nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
      2. Assert: command exits 0
    Expected Result: Laptop config unaffected by shared config changes
    Evidence: .sisyphus/evidence/task-3-laptop-eval.txt
  ```

  **Commit**: YES (groups with Tasks 1, 2)
  - Message: `refactor(station): swap NVIDIA for AMD GPU and disable AI services`
  - Files: `modules/home-manager/desktop/hyprland/default.nix`, `modules/home-manager/misc/zen-browser.nix`, `hosts/vnpc-21/default.nix`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run `nix eval`). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `nix fmt -- --check .` to verify formatting. Review all changed files for: commented-out code, unused imports, inconsistent patterns. Check that vnpc-21 overrides follow existing host config style (section comments, `lib.mkForce`/`lib.mkAfter` usage).
  Output: `Format [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  Execute EVERY QA scenario from EVERY task. Run all `nix eval` assertions. Verify no cross-contamination between hosts. Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Eval [N/N] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git diff). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Single commit** after all 3 tasks: `refactor(station): swap NVIDIA for AMD GPU and disable AI services`
- Files: `hosts/station/default.nix`, `modules/nixos/hardware/amd-gpu.nix`, `modules/home-manager/desktop/hyprland/default.nix`, `modules/home-manager/misc/zen-browser.nix`, `hosts/vnpc-21/default.nix`
- Pre-commit: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath && nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath && nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath`

---

## Success Criteria

### Verification Commands
```bash
nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath  # Expected: succeeds (no eval errors)
nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath  # Expected: succeeds
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath   # Expected: succeeds
nix eval --json '.#nixosConfigurations.station.config.services.xserver.videoDrivers'  # Expected: ["amdgpu"]
nix eval --json '.#nixosConfigurations.VNPC-21.config.services.xserver.videoDrivers'  # Expected: contains "nvidia"
nix eval '.#nixosConfigurations.station.config.services.ollama.enable'       # Expected: false
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All three hosts eval successfully
- [ ] Station has amdgpu, no nvidia
- [ ] vnpc-21 has nvidia, retains workarounds
- [ ] Laptop unaffected (eval passes, no regressions)
