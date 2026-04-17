# Flake Unification — Critical + High Priority Fixes

## TL;DR

> **Quick Summary**: Fix critical data loss risk (PostgreSQL backups), eliminate IP duplication via centralized inventory, deduplicate server networking, and extract the media group to its own module.
> 
> **Deliverables**:
> - `parts/inventory.nix` — single source of truth for all host IPs
> - PostgreSQL daily backup timer on sugar
> - `mkServerNetwork` helper in `parts/lib.nix`
> - `modules/server/media-group.nix` — standalone media group module
> - Cleaned up outdated staging comments
> - Fixed `security.nix` namespace nesting
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Task 3 (inventory) → Tasks 5-7 (consumers) → Final Verification

---

## Context

### Original Request
User asked for a comprehensive audit of their NixOS flake to find improvement and unification opportunities. After reviewing 120+ modules, 9 hosts, and all infrastructure files, we identified findings at Critical, High, Medium, and Low priority. User chose to address Critical + High only.

### Interview Summary
**Key Discussions**:
- PostgreSQL backups: local daily `pg_dumpall` to `/var/backup`, 7-day retention
- IP centralization: `parts/inventory.nix` as flat attrset, referenced by Caddy, deploy.nix, host configs
- Server networking: `mkServerNetwork` function in `parts/lib.nix` (NOT a module)
- Media group: extract from `arr.nix` to standalone `modules/server/media-group.nix`
- Staging comments: outdated, just clean them up
- security.nix: trivial namespace fix

**Research Findings**:
- Networking blocks are NOT identical across servers — byob uses different gateway (10.10.50.1) and nameserver (10.10.10.1)
- spiders (VPS) has completely different networking (eth0, public IP, IPv6) — must NOT use mkServerNetwork
- Media group GID 1000 — may collide with odin's primary GID (verify before changing)
- Caddy config references IPs for managed servers AND external infrastructure (TrueNAS, PVE, Home Assistant, etc.)
- nero hardcodes sugar's IP (10.10.30.111) for matrix homeserver
- psychosocial hardcodes sugar's IP for SSH NAT forwarding (line 358)

### Metis Review
**Identified Gaps** (addressed):
- Networking blocks differ per subnet — mkServerNetwork must parameterize gateway + nameservers
- GID 1000 collision risk — plan includes verification step before extraction
- Caddy config has external IPs (TrueNAS, PVE) that aren't NixOS hosts — inventory should include these
- pg_dumpall vs per-db pg_dump — sugar runs a single PostgreSQL cluster, pg_dumpall is correct
- Colmena eval path — inventory.nix must be importable from deploy.nix context

---

## Work Objectives

### Core Objective
Eliminate the highest-risk issues (no backups, IP duplication, hidden dependencies) while preserving identical derivation output for all hosts except where new behavior is added (backup timer).

### Concrete Deliverables
- `parts/inventory.nix` — IP registry for all hosts + external infrastructure
- Modified `parts/lib.nix` — adds `mkServerNetwork` function
- Modified `parts/deploy.nix` — references inventory for `targetHost`
- Modified `hosts/psychosocial/default.nix` — Caddy uses inventory IPs via `let` bindings
- Modified `hosts/{pulse,sugar,byob,nero}/default.nix` — use `mkServerNetwork`, remove staging comments
- Modified `modules/server/postgresql.nix` — adds backup timer + rotation
- New `modules/server/media-group.nix` — standalone media group definition
- Modified `modules/server/arr.nix` — removes inline media group definition
- Modified `modules/server/default.nix` — imports media-group.nix
- Modified `modules/nixos/security.nix` — fixed namespace nesting

### Definition of Done
- [ ] `nix flake check` passes
- [ ] `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` succeeds for all 9 hosts
- [ ] Zero raw IP literals in `.nix` files outside `parts/inventory.nix` and `hosts/spiders/default.nix`
- [ ] PostgreSQL backup timer exists in sugar's systemd unit list
- [ ] `media` group is defined even when `server.arr` is disabled (as long as `server.media-group` is enabled)

### Must Have
- Inventory covers ALL IPs currently in Caddy config (managed + external infrastructure)
- mkServerNetwork accepts IP, prefixLength, gateway, nameservers as parameters
- Backup uses `pg_dumpall` with write-then-rename to prevent partial dumps
- Media group module has its own enable option following server module conventions

### Must NOT Have (Guardrails)
- DO NOT restructure Caddy routing logic — only extract IPs, keep all handle/reverse_proxy structure intact
- DO NOT change any actual IP addresses, ports, or network behavior — purely structural refactoring
- DO NOT add off-host backup, monitoring, or alerting to the backup task
- DO NOT normalize spiders networking — it's a VPS with legitimately different config
- DO NOT add new module options beyond what's strictly needed
- DO NOT change media group GID without first verifying it doesn't collide with odin's primary GID
- DO NOT touch port standardization, secrets cleanup, or other out-of-scope items

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO (NixOS flake — no unit test framework)
- **Automated tests**: None
- **Framework**: N/A
- **Verification method**: `nix eval` per host + `nix flake check` + grep for raw IP literals

### QA Policy
Every task MUST run `nix eval` for affected hosts after changes.
Evidence saved to `.sisyphus/evidence/task-{N}-{description}.txt`.

- **NixOS modules**: Use Bash — `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
- **Structural changes**: Use Grep — verify no raw IP literals remain outside inventory
- **Backup timer**: Use Bash — `nix eval` to verify systemd timer is in config

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — independent foundations):
├── Task 1: Fix security.nix namespace [quick]
├── Task 2: Clean up staging cutover comments [quick]
├── Task 3: Create parts/inventory.nix [quick]
└── Task 4: Create modules/server/media-group.nix + update arr.nix [quick]

Wave 2 (After Task 3 — inventory consumers):
├── Task 5: Add mkServerNetwork to lib.nix + update host configs [unspecified-high]
├── Task 6: Update psychosocial Caddy to use inventory [unspecified-high]
└── Task 7: Update deploy.nix to use inventory [quick]

Wave 3 (After Wave 1 — independent):
└── Task 8: Add PostgreSQL backup to postgresql.nix [unspecified-high]

Wave FINAL (After ALL tasks):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real QA — nix eval all 9 hosts (unspecified-high)
└── F4: Scope fidelity check (deep)
→ Present results → Get explicit user okay
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1 | — | — | 1 |
| 2 | — | — | 1 |
| 3 | — | 5, 6, 7 | 1 |
| 4 | — | — | 1 |
| 5 | 3 | F1-F4 | 2 |
| 6 | 3 | F1-F4 | 2 |
| 7 | 3 | F1-F4 | 2 |
| 8 | — | F1-F4 | 3 |

### Agent Dispatch Summary

- **Wave 1**: 4 tasks — T1 `quick`, T2 `quick`, T3 `quick`, T4 `quick`
- **Wave 2**: 3 tasks — T5 `unspecified-high`, T6 `unspecified-high`, T7 `quick`
- **Wave 3**: 1 task — T8 `unspecified-high`
- **FINAL**: 4 tasks — F1 `oracle`, F2 `unspecified-high`, F3 `unspecified-high`, F4 `deep`

---

## TODOs

- [x] 1. Fix security.nix namespace nesting

  **What to do**:
  - In `modules/nixos/security.nix`, restructure lines 11-19 so `insecurePackages` is nested inside the `options.security` block instead of being a sibling path
  - Current (wrong): `options.security = { enable = ...; };` then `options.security.insecurePackages = { enable = ...; };` as separate entries
  - Correct: `options.security = { enable = ...; insecurePackages = { enable = ...; }; };`
  - The `config` block (lines 21-58) using `cfg.insecurePackages.enable` and `cfg.enable` remains unchanged — it already references correctly

  **Must NOT do**:
  - Do NOT change any config logic, only the options block structure
  - Do NOT rename the option path — `config.security.insecurePackages.enable` must still work

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/nixos/security.nix:11-19` — The options block to restructure (lines 12-14 define `security`, lines 16-18 define `security.insecurePackages` as a separate path)

  **Acceptance Criteria**:

  ```
  Scenario: security.nix evaluates correctly after namespace fix
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath` (station enables security.insecurePackages)
      2. Run `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath` (uses security module)
    Expected Result: Both commands output a /nix/store/ path without errors
    Evidence: .sisyphus/evidence/task-1-security-eval.txt
  ```

  **Commit**: YES
  - Message: `fix(security): nest insecurePackages under security options block`
  - Files: `modules/nixos/security.nix`

- [x] 2. Clean up outdated staging IP cutover comments

  **What to do**:
  - Remove the staging cutover comments from these files (the cutover is done/no longer planned):
    - `hosts/psychosocial/default.nix:13` — remove `# Static IP — staging (change to 10.10.30.10 after cutover)`
    - `hosts/pulse/default.nix:8` — remove `# Static IP — staging (change to 10.10.30.12 after cutover)`
    - `hosts/sugar/default.nix:21` — remove `# Static IP — staging (change to 10.10.30.11 after cutover)`
    - `hosts/byob/default.nix:26` — remove `# Static IP — staging (change to 10.10.50.10 after cutover)`
    - `parts/deploy.nix:93` — remove `# Homelab servers (staging IPs — update to production after cutover)`
    - `hosts/psychosocial/default.nix:65` — remove `# --- byob (staging: 10.10.50.110) ---` (replace with just `# --- byob ---`)
    - `hosts/psychosocial/default.nix:145` — remove `# --- sugar (staging: 10.10.30.111) ---` (replace with just `# --- sugar ---`)
  - Replace staging comments with simple descriptive comments (e.g., `# Static IP` or just remove entirely)
  - Do NOT change any actual values — only comments

  **Must NOT do**:
  - Do NOT change any IP addresses or code — comments only
  - Do NOT remove non-staging comments (keep section headers like `# --- Services ---`)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `hosts/psychosocial/default.nix:13` — staging comment
  - `hosts/pulse/default.nix:8` — staging comment
  - `hosts/sugar/default.nix:21` — staging comment
  - `hosts/byob/default.nix:26` — staging comment
  - `parts/deploy.nix:93` — staging comment
  - `hosts/psychosocial/default.nix:65,145` — staging labels in Caddy section headers

  **Acceptance Criteria**:

  ```
  Scenario: No staging cutover comments remain
    Tool: Bash (grep)
    Steps:
      1. Run `grep -rn "staging" hosts/ parts/` 
      2. Run `grep -rn "cutover" hosts/ parts/`
    Expected Result: Zero matches for "cutover". Zero matches for "staging" in the context of IP migration.
    Evidence: .sisyphus/evidence/task-2-staging-grep.txt
  ```

  **Commit**: YES
  - Message: `chore: remove outdated staging IP cutover comments`
  - Files: `hosts/{psychosocial,pulse,sugar,byob}/default.nix`, `parts/deploy.nix`

- [x] 3. Create parts/inventory.nix — centralized IP registry

  **What to do**:
  - Create `parts/inventory.nix` as a plain Nix file (like `parts/lib.nix`) that returns an attrset of host/service IPs
  - Include ALL IPs currently referenced in `hosts/psychosocial/default.nix` Caddy config + `parts/deploy.nix` + host configs
  - Structure as a flat attrset with descriptive names:
    ```nix
    {
      # Managed NixOS servers
      psychosocial = "10.10.30.110";
      sugar = "10.10.30.111";
      pulse = "10.10.30.112";
      nero = "10.10.30.115";
      byob = "10.10.50.110";
      spiders = "netbird.pytt.io";  # Public VPS — DNS name, not IP

      # External infrastructure (not managed by this flake)
      truenas = "10.10.10.20";
      pve1 = "10.10.10.227";
      pve2 = "10.10.10.228";
      jellyfin = "10.10.10.20";  # TrueNAS k8s (port 30013 stays in Caddy config)
      openwebui = "10.10.10.10";
      ollama = "10.10.10.163";
      craftbeerpi = "10.10.20.174";
      homeassistant = "10.10.20.205";
    }
    ```
  - This file is NOT a NixOS module — it's a pure data file imported with `import ./inventory.nix`
  - Verify the file is importable from both `parts/deploy.nix` and host config contexts

  **Must NOT do**:
  - Do NOT make this a NixOS module with options — keep it as a simple attrset
  - Do NOT add ports, domains, or other metadata (IPs only, except spiders DNS name)
  - Do NOT consume this file yet — Tasks 5-7 will do that

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4)
  - **Blocks**: Tasks 5, 6, 7
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `parts/lib.nix` — Example of a plain Nix file (not a module) in `parts/` that returns data
  - `hosts/psychosocial/default.nix:50-320` — All IPs in Caddy config to extract
  - `parts/deploy.nix:94-122` — All targetHost IPs to extract

  **IP Inventory** (extracted from current code — executor must verify completeness):
  - psychosocial: `10.10.30.110` (psychosocial:19, deploy.nix:111)
  - sugar: `10.10.30.111` (sugar:27, psychosocial:149-249, deploy.nix:101, psychosocial NAT:358)
  - pulse: `10.10.30.112` (pulse:14, psychosocial:116-142, deploy.nix:96)
  - nero: `10.10.30.115` (nero:18, deploy.nix:121)
  - byob: `10.10.50.110` (byob:32, psychosocial:69-104, deploy.nix:106)
  - truenas: `10.10.10.20` (psychosocial:256,283)
  - pve1: `10.10.10.227` (psychosocial:263)
  - pve2: `10.10.10.228` (psychosocial:273)
  - openwebui: `10.10.10.10` (psychosocial:305)
  - ollama: `10.10.10.163` (psychosocial:310)
  - craftbeerpi: `10.10.20.174` (psychosocial:295)
  - homeassistant: `10.10.20.205` (psychosocial:300)

  **Acceptance Criteria**:

  ```
  Scenario: inventory.nix is valid Nix and importable
    Tool: Bash
    Steps:
      1. Run `nix eval --expr 'import ./parts/inventory.nix'` from the flake root
      2. Verify output is an attrset with expected keys
    Expected Result: Returns attrset with keys: psychosocial, sugar, pulse, nero, byob, spiders, truenas, pve1, pve2, openwebui, ollama, craftbeerpi, homeassistant
    Evidence: .sisyphus/evidence/task-3-inventory-eval.txt
  ```

  **Commit**: YES
  - Message: `feat(infra): add parts/inventory.nix as centralized IP registry`
  - Files: `parts/inventory.nix`

- [x] 4. Extract media group to standalone module

  **What to do**:
  - Create `modules/server/media-group.nix` following server module conventions:
    ```nix
    { config, lib, ... }:
    let cfg = config.server.media-group;
    in {
      options.server.media-group = {
        enable = lib.mkEnableOption "shared media group for arr/download services";
        gid = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = "GID for the media group";
        };
      };
      config = lib.mkIf cfg.enable {
        users.groups.media.gid = cfg.gid;
      };
    }
    ```
  - BEFORE setting the GID, verify that GID 1000 doesn't collide with odin's primary group:
    - Check `users.users.odin` or `users.groups.odin` in host configs and modules
    - If collision exists, document it but keep GID 1000 (matching current behavior) — changing it is out of scope
  - Remove `users.groups.media.gid = 1000;` from `modules/server/arr.nix:36`
  - Add `modules/server/media-group.nix` import to `modules/server/default.nix`
  - In host configs that use media services, ensure `server.media-group.enable = true` is set:
    - `hosts/byob/default.nix` — add `server.media-group.enable = true;` (byob uses arr + transmission + nzbget)
  - Consider: arr.nix could assert `server.media-group.enable` is true, OR media-group could be auto-enabled. Prefer explicit enable in host config for clarity.

  **Must NOT do**:
  - Do NOT change the GID value (keep 1000 to match current behavior)
  - Do NOT modify transmission.nix or nzbget.nix — they already reference `group = "media"` which will work
  - Do NOT add user definitions — only the group

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/server/arr.nix:36` — Current inline `users.groups.media.gid = 1000;` to remove
  - `modules/server/transmission.nix:29` — Uses `group = "media"` (depends on media group existing)
  - `modules/server/nzbget.nix:28` — Uses `group = "media"` (depends on media group existing)
  - `modules/server/caddy.nix` — Example of a simple server module with enable option (pattern to follow)

  **API/Type References**:
  - `modules/server/CLAUDE.md` — Server module conventions (options.server.<name> namespace)

  **Acceptance Criteria**:

  ```
  Scenario: Media group exists when media-group module enabled without arr
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath`
      2. Verify no eval errors — media group is defined by media-group.nix, not arr.nix
    Expected Result: Successful eval, no "media group undefined" errors
    Evidence: .sisyphus/evidence/task-4-media-group-eval.txt

  Scenario: GID collision check
    Tool: Bash (grep)
    Steps:
      1. Run `grep -rn "gid.*1000\|uid.*1000" modules/ hosts/ profiles/`
      2. Document findings — if odin uses GID 1000, note it but don't change
    Expected Result: Document whether GID 1000 collides. If so, add a comment in media-group.nix.
    Evidence: .sisyphus/evidence/task-4-gid-check.txt
  ```

  **Commit**: YES
  - Message: `refactor(server): extract media group to standalone module`
  - Files: `modules/server/media-group.nix`, `modules/server/arr.nix`, `modules/server/default.nix`, `hosts/byob/default.nix`

- [x] 5. Add mkServerNetwork to lib.nix + update all server host configs

  **What to do**:
  - Add a `mkServerNetwork` function to `parts/lib.nix` that generates the networking block for LAN servers
  - The function must accept parameters for per-host differences:
    ```nix
    mkServerNetwork = { ip, prefixLength ? 24, gateway, nameservers ? [ gateway "1.1.1.1" ], interface ? "ens18" }: {
      networking = {
        useDHCP = false;
        interfaces.${interface} = {
          ipv4.addresses = [{ address = ip; inherit prefixLength; }];
        };
        defaultGateway = gateway;
        inherit nameservers;
      };
    };
    ```
  - Import `inventory.nix` in `lib.nix` to use IPs: `inventory = import ./inventory.nix;`
  - Export `mkServerNetwork` and `inventory` from lib.nix
  - Update each LAN server host config to use `mkServerNetwork` instead of inline networking:
    - `hosts/psychosocial/default.nix:14-29` → replace with `imports = [ (lib.mkServerNetwork { ip = inventory.psychosocial; gateway = "10.10.30.1"; }) ];` or inline the result
    - `hosts/pulse/default.nix:9-24` → same pattern with `inventory.pulse`
    - `hosts/sugar/default.nix:22-37` → same pattern with `inventory.sugar`
    - `hosts/byob/default.nix:27-42` → uses different gateway: `gateway = "10.10.50.1"; nameservers = [ "10.10.10.1" "1.1.1.1" ];`
    - `hosts/nero/default.nix:13-27` → same pattern with `inventory.nero` (note: slightly different nix structure but same values as psychosocial/pulse/sugar)
  - **IMPORTANT**: `mkServerNetwork` returns a config attrset, NOT a module. Host configs should use it like:
    ```nix
    let
      lib' = import ../../parts/lib.nix { inherit inputs; };
    in {
      # ... existing imports ...
    } // lib'.mkServerNetwork { ip = lib'.inventory.psychosocial; gateway = "10.10.30.1"; }
    ```
    OR the function could be passed via `_module.args` — choose whichever integrates cleanest with the existing `serverModules` pattern in lib.nix. The executor should check how `hostPath` configs currently access shared values.
  - Do NOT touch `hosts/spiders/default.nix` — it has completely different networking (eth0, public IP, IPv6)

  **Must NOT do**:
  - Do NOT change spiders networking
  - Do NOT change any actual IP, gateway, or nameserver values
  - Do NOT make mkServerNetwork a NixOS module — keep it as a function returning a config attrset
  - Do NOT change the networking behavior — output must be identical to current inline blocks

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 6, 7)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 3 (inventory.nix must exist)

  **References**:

  **Pattern References**:
  - `parts/lib.nix:41-72` — `hostModules` function pattern (similar helper function structure)
  - `parts/lib.nix:74-91` — `serverModules` function pattern
  - `hosts/psychosocial/default.nix:14-29` — Networking block to replace (gateway: 10.10.30.1)
  - `hosts/pulse/default.nix:9-24` — Networking block to replace (gateway: 10.10.30.1)
  - `hosts/sugar/default.nix:22-37` — Networking block to replace (gateway: 10.10.30.1)
  - `hosts/byob/default.nix:27-42` — Networking block to replace (gateway: 10.10.50.1, nameservers: ["10.10.10.1" "1.1.1.1"])
  - `hosts/nero/default.nix:13-27` — Networking block to replace (gateway: 10.10.30.1)

  **Critical Detail — byob differs**:
  - Gateway: `10.10.50.1` (not `10.10.30.1`)
  - Nameservers: `["10.10.10.1" "1.1.1.1"]` (not `["10.10.30.1" "1.1.1.1"]`)
  - These MUST be parameterized, not hardcoded as defaults

  **Acceptance Criteria**:

  ```
  Scenario: All 5 LAN server hosts eval identically after networking dedup
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath`
      2. Run `nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath`
      3. Run `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath`
      4. Run `nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath`
      5. Run `nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath`
      6. Run `nix eval .#nixosConfigurations.spiders.config.system.build.toplevel.drvPath` (unchanged, must still work)
    Expected Result: All 6 commands produce /nix/store/ paths without errors
    Evidence: .sisyphus/evidence/task-5-networking-eval.txt

  Scenario: No inline networking blocks remain in LAN server hosts
    Tool: Bash (grep)
    Steps:
      1. Run `grep -l "useDHCP = false" hosts/*/default.nix`
    Expected Result: Only `hosts/spiders/default.nix` should contain `useDHCP = false`
    Evidence: .sisyphus/evidence/task-5-networking-grep.txt
  ```

  **Commit**: YES
  - Message: `refactor(infra): add mkServerNetwork helper and deduplicate host networking`
  - Files: `parts/lib.nix`, `hosts/{psychosocial,pulse,sugar,byob,nero}/default.nix`

- [x] 6. Update psychosocial Caddy config to use inventory IPs

  **What to do**:
  - In `hosts/psychosocial/default.nix`, add a `let` binding at the top to import inventory:
    ```nix
    let
      inventory = import ../../parts/inventory.nix;
    in
    ```
  - Replace ALL hardcoded IPs in the Caddy `extraConfig` string with `${inventory.<name>}` interpolation:
    - `10.10.50.110` → `${inventory.byob}` (lines 69, 74, 79, 84, 89, 94, 99, 104)
    - `10.10.30.112` → `${inventory.pulse}` (lines 116, 120, 125, 131, 136, 142)
    - `10.10.30.111` → `${inventory.sugar}` (lines 149, 154, 159, 164, 172, 183, 188, 194, 199, 210, 215, 221, 243, 249)
    - `10.10.10.20` → `${inventory.truenas}` (lines 256, 283)
    - `10.10.10.227` → `${inventory.pve1}` (line 263)
    - `10.10.10.228` → `${inventory.pve2}` (line 273)
    - `10.10.20.174` → `${inventory.craftbeerpi}` (line 295)
    - `10.10.20.205` → `${inventory.homeassistant}` (line 300)
    - `10.10.10.10` → `${inventory.openwebui}` (line 305)
    - `10.10.10.163` → `${inventory.ollama}` (line 310)
  - Also update the NAT forwarding destination on line 358: `"10.10.30.111:22"` → `"${inventory.sugar}:22"`
  - Also update the networking block IP (line 19) if Task 5 hasn't already handled it via mkServerNetwork
  - Keep `127.0.0.1` references as-is — those are localhost services on psychosocial itself

  **Must NOT do**:
  - Do NOT change Caddy routing structure (handle blocks, matchers, auth config)
  - Do NOT change any ports — only IPs
  - Do NOT replace `127.0.0.1` — those are intentionally localhost
  - Do NOT change `auth.pytt.io` references — that's a domain, not an IP

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 7)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 3 (inventory.nix must exist)

  **References**:

  **Pattern References**:
  - `hosts/psychosocial/default.nix:38-343` — Full Caddy extraConfig block (all IPs to replace)
  - `hosts/psychosocial/default.nix:352-363` — NAT forwarding (sugar IP to replace)
  - `parts/inventory.nix` — Source of truth (created by Task 3)

  **Acceptance Criteria**:

  ```
  Scenario: Psychosocial evals correctly with inventory IPs
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath`
    Expected Result: Outputs /nix/store/ path without errors
    Evidence: .sisyphus/evidence/task-6-psychosocial-eval.txt

  Scenario: No raw IPs remain in psychosocial config (except 127.0.0.1)
    Tool: Bash (grep)
    Steps:
      1. Run `grep -n '10\.\(10\|20\)\.' hosts/psychosocial/default.nix`
    Expected Result: Zero matches — all IPs replaced with inventory references
    Failure Indicators: Any line containing a 10.10.x.x or 10.20.x.x IP
    Evidence: .sisyphus/evidence/task-6-ip-grep.txt
  ```

  **Commit**: YES
  - Message: `refactor(psychosocial): use inventory IPs in Caddy config`
  - Files: `hosts/psychosocial/default.nix`

- [x] 7. Update deploy.nix to use inventory IPs

  **What to do**:
  - In `parts/deploy.nix`, import inventory at the top of the let block:
    ```nix
    inventory = import ./inventory.nix;
    ```
  - Replace all hardcoded `targetHost` IPs with inventory references:
    - Line 96: `targetHost = "10.10.30.112"` → `targetHost = inventory.pulse;`
    - Line 101: `targetHost = "10.10.30.111"` → `targetHost = inventory.sugar;`
    - Line 106: `targetHost = "10.10.50.110"` → `targetHost = inventory.byob;`
    - Line 111: `targetHost = "10.10.30.110"` → `targetHost = inventory.psychosocial;`
    - Line 116: `targetHost = "netbird.pytt.io"` → `targetHost = inventory.spiders;`
    - Line 121: `targetHost = "10.10.30.115"` → `targetHost = inventory.nero;`
  - Desktop hosts (laptop, VNPC-21, station) use hostnames, not IPs — leave them as-is

  **Must NOT do**:
  - Do NOT change desktop host targetHost values (they use hostnames)
  - Do NOT change mkColmenaHost or mkColmenaServer function definitions
  - Do NOT change any other deploy.nix logic

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6)
  - **Blocks**: F1-F4
  - **Blocked By**: Task 3 (inventory.nix must exist)

  **References**:

  **Pattern References**:
  - `parts/deploy.nix:94-122` — All server targetHost entries to update
  - `parts/inventory.nix` — Source of truth (created by Task 3)

  **Acceptance Criteria**:

  ```
  Scenario: Deploy config evaluates correctly with inventory
    Tool: Bash
    Steps:
      1. Run `nix eval .#colmena.psychosocial` (or equivalent colmena eval)
      2. If colmena eval isn't straightforward, run `nix flake check` instead
    Expected Result: No evaluation errors
    Evidence: .sisyphus/evidence/task-7-deploy-eval.txt

  Scenario: No raw IPs remain in deploy.nix
    Tool: Bash (grep)
    Steps:
      1. Run `grep -n '10\.\(10\|20\|50\)\.' parts/deploy.nix`
    Expected Result: Zero matches
    Evidence: .sisyphus/evidence/task-7-deploy-grep.txt
  ```

  **Commit**: YES
  - Message: `refactor(deploy): use inventory IPs for colmena targetHost`
  - Files: `parts/deploy.nix`

- [x] 8. Add PostgreSQL daily backup with 7-day retention

  **What to do**:
  - Add backup functionality to `modules/server/postgresql.nix` as new options under `server.postgresql`:
    ```nix
    backup = {
      enable = lib.mkEnableOption "daily PostgreSQL backup";
      dir = lib.mkOption {
        type = lib.types.str;
        default = "/var/backup/postgresql";
        description = "Directory for backup dumps";
      };
      retention = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of daily backups to retain";
      };
    };
    ```
  - Add a systemd timer + service that:
    1. Creates backup dir if missing (`systemd.tmpfiles.rules`)
    2. Runs `pg_dumpall` to a timestamped file with write-then-rename pattern:
       - Dump to `${cfg.backup.dir}/.dump-in-progress.sql.gz`
       - On success, rename to `${cfg.backup.dir}/pg_dumpall-$(date +%Y%m%d-%H%M%S).sql.gz`
       - This prevents partial dumps from being treated as valid
    3. Deletes dumps older than `cfg.backup.retention` days
    4. Runs daily at 03:00 (configurable via systemd timer)
  - The service must:
    - Run as `postgres` user (has DB access)
    - Use `Type = "oneshot"`
    - Pipe through `gzip` for compression
    - Join `homelab.target` (partOf + wantedBy)
  - Enable backup by default in sugar's host config:
    ```nix
    server.postgresql.backup.enable = true;
    ```

  **Must NOT do**:
  - Do NOT add off-host backup (rsync, S3, etc.)
  - Do NOT add monitoring/alerting for backup failures
  - Do NOT add restore functionality
  - Do NOT modify existing postgresql.nix options or config — only ADD backup section
  - Do NOT use `pg_dump` per-database — use `pg_dumpall` for the entire cluster

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (independent of all other tasks)
  - **Parallel Group**: Wave 3 (solo, runs alongside Wave 2)
  - **Blocks**: F1-F4
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/server/postgresql.nix:79-89` — Existing `postgresql-set-passwords` service pattern (similar oneshot systemd service)
  - `modules/server/postgresql.nix:44-113` — Full postgresql config block to add backup section to
  - `modules/server/forgejo.nix:82-86` — Forgejo's own dump config (example of backup pattern in this codebase)

  **API/Type References**:
  - `modules/server/CLAUDE.md` — Server module conventions (homelab.target membership required)

  **External References**:
  - PostgreSQL `pg_dumpall` docs — outputs entire cluster as SQL

  **Host Config Reference**:
  - `hosts/sugar/default.nix:42-53` — Where `server.postgresql` is configured (add `backup.enable = true` here)

  **Acceptance Criteria**:

  ```
  Scenario: PostgreSQL backup timer exists in sugar config
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.sugar.config.systemd.timers` --json and check for postgresql-backup timer
      2. Alternatively: `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath`
    Expected Result: Eval succeeds, timer for postgresql-backup is present
    Evidence: .sisyphus/evidence/task-8-backup-eval.txt

  Scenario: Backup service uses write-then-rename pattern
    Tool: Bash (grep)
    Steps:
      1. Read `modules/server/postgresql.nix` and verify the backup script contains:
         - `.dump-in-progress` temporary file
         - `mv` or rename after successful dump
         - `find ... -mtime +${toString cfg.backup.retention} -delete` for cleanup
    Expected Result: All three patterns present in the script
    Evidence: .sisyphus/evidence/task-8-backup-script.txt

  Scenario: Other hosts unaffected (backup not enabled by default)
    Tool: Bash
    Steps:
      1. Run `nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath`
      2. Run `nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath`
    Expected Result: Both eval without errors (backup disabled by default, no side effects)
    Evidence: .sisyphus/evidence/task-8-other-hosts-eval.txt
  ```

  **Commit**: YES
  - Message: `feat(postgresql): add daily pg_dumpall backup with 7-day retention`
  - Files: `modules/server/postgresql.nix`, `hosts/sugar/default.nix`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `nix flake check` + `nix fmt -- --check .`. Review all changed files for: hardcoded IPs outside inventory, inconsistent module patterns, missing `let cfg` bindings, unused imports. Check for AI slop: excessive comments, over-abstraction.
  Output: `Flake Check [PASS/FAIL] | Format [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real QA — nix eval all 9 hosts** — `unspecified-high`
  Run `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` for ALL 9 hosts: laptop, VNPC-21, station, pulse, sugar, byob, psychosocial, spiders, nero. Capture derivation paths. Grep all .nix files for raw IP patterns `\b\d+\.\d+\.\d+\.\d+\b` — only `parts/inventory.nix` and `hosts/spiders/default.nix` should contain them. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Hosts [N/9 eval pass] | IP Leaks [N files] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git diff). Verify 1:1 — everything in spec was built, nothing beyond spec. Check "Must NOT do" compliance. Detect unaccounted changes.
  Output: `Tasks [N/N compliant] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| Task | Commit Message | Files |
|------|---------------|-------|
| 1 | `fix(security): nest insecurePackages under security options block` | `modules/nixos/security.nix` |
| 2 | `chore: remove outdated staging IP cutover comments` | `hosts/{psychosocial,pulse,sugar,byob}/default.nix`, `parts/deploy.nix` |
| 3 | `feat(infra): add parts/inventory.nix as centralized IP registry` | `parts/inventory.nix` |
| 4 | `refactor(server): extract media group to standalone module` | `modules/server/media-group.nix`, `modules/server/arr.nix`, `modules/server/default.nix` |
| 5 | `refactor(infra): add mkServerNetwork helper and deduplicate host networking` | `parts/lib.nix`, `hosts/{psychosocial,pulse,sugar,byob,nero}/default.nix` |
| 6 | `refactor(psychosocial): use inventory IPs in Caddy config` | `hosts/psychosocial/default.nix` |
| 7 | `refactor(deploy): use inventory IPs for colmena targetHost` | `parts/deploy.nix` |
| 8 | `feat(postgresql): add daily pg_dumpall backup with 7-day retention` | `modules/server/postgresql.nix` |

---

## Success Criteria

### Verification Commands
```bash
nix flake check                                    # Expected: no errors
nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath  # Expected: /nix/store/...
nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath         # Expected: /nix/store/...
nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath         # Expected: /nix/store/...
nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath          # Expected: /nix/store/...
nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath          # Expected: /nix/store/...
nix eval .#nixosConfigurations.spiders.config.system.build.toplevel.drvPath       # Expected: /nix/store/...
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath        # Expected: /nix/store/...
nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath       # Expected: /nix/store/...
nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath       # Expected: /nix/store/...
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All 9 hosts eval successfully
- [ ] No raw IPs outside inventory + spiders
