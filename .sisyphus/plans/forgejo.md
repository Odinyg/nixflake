# Add Forgejo Git Forge to Sugar Server

## TL;DR

> **Quick Summary**: Add Forgejo as a self-hosted git forge on sugar (10.10.30.111) using the NixOS `services.forgejo` module, with PostgreSQL, Caddy reverse proxy via psychosocial, SSH access, Git LFS, periodic backups, and declarative admin user provisioning.
> 
> **Deliverables**:
> - `modules/server/forgejo.nix` — Forgejo NixOS module following codebase conventions
> - Updated `modules/server/default.nix` — import the new module
> - Updated `hosts/sugar/default.nix` — enable Forgejo, add DB, move Norish port
> - Updated `hosts/psychosocial/default.nix` — Caddy reverse proxy route for git.pytt.io
> - Updated `secrets/sugar.yaml` — PostgreSQL password + admin password secrets
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Task 1 (module) → Task 3 (secrets) → Task 4 (enable on sugar) → Task 5 (Caddy route) → Task 6 (verify)

---

## Context

### Original Request
User wants to add Forgejo to their apps server using NixOS services, with SSH clone support, Git LFS, backups, and an admin user.

### Interview Summary
**Key Discussions**:
- **Target host**: sugar (10.10.30.111) — the apps server
- **Domain**: git.pytt.io via Caddy on psychosocial
- **Port**: 3000 (move Norish from 3000 → 3100 to avoid collision)
- **Database**: PostgreSQL (already on sugar, add "forgejo" to databases list)
- **SSH**: Direct to sugar via LAN/netbird VPN (not through Caddy)
- **SSH_DOMAIN**: 10.10.30.111 (sugar's LAN IP — clean for clone URLs)
- **Auth**: Forgejo built-in (not Authelia SSO)
- **Admin user**: "odin" — declarative via preStart script + sops secret
- **Actions**: Enable in settings but NO runner setup (separate follow-up plan)
- **Extras**: Git LFS, periodic backups (default stateDir), admin provisioning
- **NOT included**: Email/SMTP, Authelia SSO, runner, custom themes, container registry

**Research Findings**:
- NixOS `services.forgejo` module has 38 options (nixpkgs-unstable)
- Codebase uses `sops.secrets` + `sops.templates` pattern (NOT agenix)
- Module namespace is `options.server.<name>` with enable/port/domain/dbHost
- PostgreSQL module auto-creates DB + user from `databases` list
- Caddy wildcard `*.pytt.io` with per-service `@name host name.pytt.io` matchers
- All systemd services MUST join `homelab.target`

### Metis Review
**Identified Gaps** (addressed):
- **Port 3000 collision with Norish**: Resolved — move Norish to 3100, Forgejo gets 3000
- **`createDatabase` conflict**: Resolved — set `false`, use codebase's postgresql module
- **DB password ownership**: Resolved — use `sops.templates` env file pattern (matching n8n)
- **HTTP_ADDR binding**: Resolved — bind to `0.0.0.0` so Caddy on psychosocial can reach it
- **Caddy body size for LFS**: Resolved — add request body size override
- **Service ordering**: Resolved — `After=postgresql.service postgresql-set-passwords.service`
- **Admin username cannot be "admin"**: Resolved — using "odin"
- **SSH_DOMAIN for clone URLs**: Resolved — using `10.10.30.111` (sugar LAN IP)

---

## Work Objectives

### Core Objective
Deploy Forgejo on sugar using the NixOS `services.forgejo` module with PostgreSQL, SSH access, Git LFS, backups, and a declarative admin user, accessible via `https://git.pytt.io` through Caddy.

### Concrete Deliverables
- `modules/server/forgejo.nix` — NixOS module with `options.server.forgejo`
- Updated `modules/server/default.nix` — import forgejo.nix
- Updated `hosts/sugar/default.nix` — enable Forgejo, add "forgejo" to PostgreSQL databases, move Norish port to 3100
- Updated `hosts/psychosocial/default.nix` — Caddy reverse proxy route for git.pytt.io
- Updated `secrets/sugar.yaml` — `postgresql_forgejo_password` + `forgejo_admin_password`

### Definition of Done
- [ ] `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath` succeeds
- [ ] `nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath` succeeds
- [ ] Module follows codebase conventions (namespace, options, homelab.target, sops)
- [ ] No port conflicts on sugar

### Must Have
- Forgejo service on port 3000 with PostgreSQL backend
- SSH passthrough with SSH_DOMAIN = 10.10.30.111
- Git LFS enabled
- Periodic backup via forgejo dump
- Admin user "odin" provisioned declaratively
- Registration disabled, sign-in required to view
- Caddy reverse proxy at git.pytt.io with body size override for LFS
- Actions enabled in settings (ready for future runner)
- All systemd services join homelab.target

### Must NOT Have (Guardrails)
- Do NOT set `services.forgejo.database.createDatabase = true` — conflicts with codebase postgresql module
- Do NOT use socket auth for database — use TCP `127.0.0.1` + password
- Do NOT put secret values in `settings` — they end up in the nix store
- Do NOT change `stateDir`, `user`, or `group` from defaults (`/var/lib/forgejo`, `forgejo`, `forgejo`)
- Do NOT add runner/email/SMTP/Authelia/themes/metrics/container registry config
- Do NOT use agenix — this codebase uses sops-nix
- Do NOT use admin username "admin" — Forgejo reserves it

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO (this is NixOS infrastructure config, not application code)
- **Automated tests**: None (NixOS config — verification is `nix eval` + deployment QA)
- **Framework**: N/A

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **NixOS config**: Use Bash (`nix eval`) — evaluate derivation paths, check for errors
- **Secrets**: Use Bash (`sops`) — verify secret file structure
- **Post-deploy verification**: Use Bash (`curl`, `ssh`) — verify service reachability

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — module + port fix):
├── Task 1: Create forgejo.nix module + add to imports [quick]
├── Task 2: Move Norish from port 3000 to 3100 [quick]

Wave 2 (After Wave 1 — secrets + host enablement):
├── Task 3: Add secrets to sugar.yaml [quick] (uses server-add-secrets skill)
├── Task 4: Enable Forgejo on sugar host config [quick]

Wave 3 (After Wave 2 — reverse proxy + final verification):
├── Task 5: Add Caddy reverse proxy route on psychosocial [quick]
├── Task 6: Final nix eval verification for both hosts [quick]

Wave FINAL (After deployment — 4 parallel reviews):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
├── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | 3, 4 |
| 2 | — | 4 |
| 3 | 1 | 4 |
| 4 | 1, 2, 3 | 5, 6 |
| 5 | 4 | 6 |
| 6 | 4, 5 | F1-F4 |

### Agent Dispatch Summary

- **Wave 1**: **2 tasks** — T1 → `quick` (server-add-service skill), T2 → `quick`
- **Wave 2**: **2 tasks** — T3 → `quick` (server-add-secrets skill), T4 → `quick`
- **Wave 3**: **2 tasks** — T5 → `quick`, T6 → `quick`
- **FINAL**: **4 tasks** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [ ] 1. Create Forgejo NixOS Module + Add to Imports

  **What to do**:
  - Create `modules/server/forgejo.nix` following the codebase's canonical module pattern
  - Define `options.server.forgejo` with:
    - `enable = lib.mkEnableOption "Forgejo git forge"`
    - `port = lib.mkOption { type = lib.types.port; default = 3000; }`
    - `domain = lib.mkOption { type = lib.types.str; default = "git.pytt.io"; }`
    - `dbHost = lib.mkOption { type = lib.types.str; default = "127.0.0.1"; }`
  - In `config = lib.mkIf cfg.enable { ... }`, configure:
    - **Secrets**: `sops.secrets.forgejo_admin_password = { owner = "forgejo"; };`
    - **Database env template**: `sops.templates."forgejo-env".content` with `FORGEJO__database__PASSWD=${config.sops.placeholder.postgresql_forgejo_password}` (environment-to-ini format for Forgejo)
    - **Forgejo service**: `services.forgejo.enable = true`, `database.type = "postgres"`, `database.createDatabase = false`, `database.host = cfg.dbHost`, `database.name = "forgejo"`, `database.user = "forgejo"`, `lfs.enable = true`
    - **Settings**: `server.DOMAIN = cfg.domain`, `server.ROOT_URL = "https://${cfg.domain}/"`, `server.HTTP_PORT = cfg.port`, `server.HTTP_ADDR = "0.0.0.0"`, `server.SSH_DOMAIN = "10.10.30.111"`, `server.SSH_PORT = 22`
    - **Settings (security)**: `service.DISABLE_REGISTRATION = true`, `service.REQUIRE_SIGNIN_VIEW = true`, `security.INSTALL_LOCK = true`, `security.PASSWORD_HASH_ALGO = "argon2"`, `security.MIN_PASSWORD_LENGTH = 12`, `session.COOKIE_SECURE = true`
    - **Settings (actions)**: `actions.ENABLED = true`, `actions.DEFAULT_ACTIONS_URL = "github"`
    - **Backup**: `services.forgejo.dump.enable = true`, `services.forgejo.dump.interval = "06:00"`, `services.forgejo.dump.type = "tar.zst"`
    - **Admin provisioning** in `systemd.services.forgejo-admin-setup`: A oneshot service that runs AFTER forgejo.service, using `forgejo admin user create --admin --email "admin@git.pytt.io" --username odin --password "$(tr -d '\n' < ${config.sops.secrets.forgejo_admin_password.path})" || true` (the `|| true` prevents failure if user exists)
    - **Systemd integration**: `systemd.services.forgejo = { partOf = [ "homelab.target" ]; wantedBy = [ "homelab.target" ]; after = [ "postgresql.service" "postgresql-set-passwords.service" ]; }` and set `serviceConfig.EnvironmentFile = config.sops.templates."forgejo-env".path;`
    - **Firewall**: `networking.firewall.allowedTCPPorts = [ cfg.port ];`
  - Add `./forgejo.nix` to `modules/server/default.nix` imports list (in the "# Apps (sugar)" section or similar grouping)

  **IMPORTANT implementation notes**:
  - The `services.forgejo.secrets` option uses systemd `LoadCredential` for `environment-to-ini` — this is for settings that need secrets. But for database password, we use the `sops.templates` env file approach since the codebase's postgresql module already creates the `postgresql_forgejo_password` sops secret with specific ownership. The environment-to-ini format uses double underscores: `FORGEJO__section__KEY=value`
  - The admin setup service MUST use `After=forgejo.service` and `Requires=forgejo.service` since it needs the database to be migrated first
  - `HTTP_ADDR = "0.0.0.0"` is required because Caddy is on psychosocial (different host), not localhost

  **Must NOT do**:
  - Do NOT set `services.forgejo.database.createDatabase = true`
  - Do NOT use socket auth (`database.socket`)
  - Do NOT put any secrets in `settings` (nix store exposure)
  - Do NOT change stateDir/user/group from defaults
  - Do NOT add email/SMTP/runner/Authelia/themes config
  - Do NOT use agenix (use sops-nix)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file creation + one import line addition, following well-documented patterns
  - **Skills**: [`server-add-service`]
    - `server-add-service`: This skill knows the exact codebase conventions for adding server modules

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: Tasks 3, 4
  - **Blocked By**: None (can start immediately)

  **References** (CRITICAL):

  **Pattern References** (existing code to follow):
  - `modules/server/n8n.nix` — Primary pattern to follow: NixOS service + PostgreSQL + sops.templates env file + homelab.target. Shows exact structure for options namespace, sops template content format, systemd service integration
  - `modules/server/nextcloud.nix` — Secondary pattern: shows `sops.secrets` with `owner = "forgejo"` for service-specific secrets, admin password handling
  - `modules/server/default.nix` — Where to add the import. Look at the existing import list organization

  **API/Type References** (contracts to implement against):
  - NixOS `services.forgejo.*` options — 38 options documented above in Context section
  - `services.forgejo.settings` — free-form app.ini sections (server, service, security, actions, session)
  - `services.forgejo.database` — type, host, name, user, createDatabase, passwordFile
  - `services.forgejo.dump` — enable, interval, type, backupDir

  **External References**:
  - NixOS Wiki Forgejo: https://wiki.nixos.org/wiki/Forgejo — Shows preStart admin creation pattern, SSH setup, Actions config
  - Forgejo config cheat sheet: https://forgejo.org/docs/latest/admin/config-cheat-sheet/ — All app.ini settings
  - `environment-to-ini` format: `FORGEJO__section__KEY=value` (double underscores for section separator)

  **WHY Each Reference Matters**:
  - `n8n.nix` — Copy the exact options structure (enable, port, domain, dbHost), sops template pattern, and systemd integration. This is the canonical template.
  - `nextcloud.nix` — Shows how to handle service-specific secrets with `owner = "forgejo"` for file read access
  - NixOS Wiki — Shows the `preStart` admin user creation pattern and `|| true` idiom for idempotency

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Module file exists with correct structure
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Run: test -f modules/server/forgejo.nix && echo "EXISTS" || echo "MISSING"
      2. Run: grep -c "options.server.forgejo" modules/server/forgejo.nix
      3. Run: grep -c "lib.mkEnableOption" modules/server/forgejo.nix
      4. Run: grep -c "lib.mkIf cfg.enable" modules/server/forgejo.nix
      5. Run: grep -c "homelab.target" modules/server/forgejo.nix
      6. Run: grep -c "createDatabase = false" modules/server/forgejo.nix
    Expected Result: File exists, all greps return >= 1
    Failure Indicators: File missing, or any grep returns 0
    Evidence: .sisyphus/evidence/task-1-module-structure.txt

  Scenario: Module imported in default.nix
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Run: grep "forgejo" modules/server/default.nix
    Expected Result: ./forgejo.nix appears in imports
    Failure Indicators: No match found
    Evidence: .sisyphus/evidence/task-1-import-check.txt

  Scenario: No forbidden patterns in module
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Run: grep -c "createDatabase = true" modules/server/forgejo.nix (should be 0)
      2. Run: grep -c "database.socket" modules/server/forgejo.nix (should be 0)
      3. Run: grep -c "agenix\|age.secrets" modules/server/forgejo.nix (should be 0)
      4. Run: grep -c "mailer\|SMTP\|smtp" modules/server/forgejo.nix (should be 0)
    Expected Result: All greps return 0
    Failure Indicators: Any grep returns > 0
    Evidence: .sisyphus/evidence/task-1-forbidden-patterns.txt
  ```

  **Commit**: YES (groups with Task 2)
  - Message: `feat(server): add forgejo module and move norish port`
  - Files: `modules/server/forgejo.nix`, `modules/server/default.nix`, `modules/server/norish.nix`
  - Pre-commit: `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath` (may fail until secrets exist — that's expected)

- [ ] 2. Move Norish from Port 3000 to Port 3100

  **What to do**:
  - Edit `modules/server/norish.nix` — change the port default from `3000` to `3100`
  - That's it — the port option is used throughout the module so no other changes needed

  **Must NOT do**:
  - Do NOT change any other Norish settings
  - Do NOT touch the Norish container config beyond the port default

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single line change in one file
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: Task 4
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `modules/server/norish.nix:14` — The line `default = 3000;` that needs to change to `default = 3100;`

  **WHY This Reference Matters**:
  - This is a single line change. The port option cascades through the module — no other changes needed.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Norish port changed to 3100
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Run: grep "default = 3100" modules/server/norish.nix
      2. Run: grep -c "default = 3000" modules/server/norish.nix (should be 0)
    Expected Result: Line 1 returns match, line 2 returns 0
    Failure Indicators: Port still 3000 or 3100 not found
    Evidence: .sisyphus/evidence/task-2-norish-port.txt
  ```

  **Commit**: YES (groups with Task 1)
  - Message: `feat(server): add forgejo module and move norish port`
  - Files: `modules/server/norish.nix`

- [ ] 3. Add Forgejo Secrets to sugar.yaml

  **What to do**:
  - Edit `secrets/sugar.yaml` (using `sops secrets/sugar.yaml` or `just secrets-sugar`) to add:
    - `postgresql_forgejo_password` — a strong random password (generate with `openssl rand -base64 32`)
    - `forgejo_admin_password` — the admin user password for "odin" (generate with `openssl rand -base64 32`)
  - These secrets are auto-encrypted by sops using the `homelab_general` age key group defined in `.sops.yaml`

  **Must NOT do**:
  - Do NOT commit plaintext passwords
  - Do NOT modify existing secrets in the file
  - Do NOT add secrets to any other file (only sugar.yaml)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Adding two keys to an encrypted YAML file
  - **Skills**: [`server-add-secrets`]
    - `server-add-secrets`: This skill knows the sops workflow for adding secrets to encrypted YAML files

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 4 — but Task 4 depends on this, so run 3 first)
  - **Blocks**: Task 4
  - **Blocked By**: Task 1 (module must exist to reference secrets)

  **References**:

  **Pattern References**:
  - `secrets/sugar.yaml` — Existing secrets file for sugar host. Add new keys following existing naming pattern
  - `.sops.yaml` — SOPS configuration showing `homelab_general` key group for sugar

  **External References**:
  - `modules/server/postgresql.nix` — Shows that `postgresql_forgejo_password` is auto-referenced when "forgejo" is in the databases list

  **WHY Each Reference Matters**:
  - `sugar.yaml` — Must add secrets in the same format as existing entries
  - `postgresql.nix` — Confirms the naming convention `postgresql_<dbname>_password` is mandatory for auto-wiring

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Secrets exist in sugar.yaml (encrypted)
    Tool: Bash
    Preconditions: sops is available and age key is accessible
    Steps:
      1. Run: sops -d secrets/sugar.yaml 2>/dev/null | grep -c "postgresql_forgejo_password"
      2. Run: sops -d secrets/sugar.yaml 2>/dev/null | grep -c "forgejo_admin_password"
    Expected Result: Both greps return 1
    Failure Indicators: Either grep returns 0 (secret missing)
    Evidence: .sisyphus/evidence/task-3-secrets-check.txt

  Scenario: Secrets file is valid SOPS-encrypted YAML
    Tool: Bash
    Preconditions: sops available
    Steps:
      1. Run: sops -d secrets/sugar.yaml > /dev/null 2>&1 && echo "VALID" || echo "INVALID"
    Expected Result: "VALID"
    Failure Indicators: "INVALID" — file corrupted or encryption broken
    Evidence: .sisyphus/evidence/task-3-sops-valid.txt
  ```

  **Commit**: YES
  - Message: `chore(secrets): add forgejo secrets to sugar`
  - Files: `secrets/sugar.yaml`

- [ ] 4. Enable Forgejo on Sugar Host Config

  **What to do**:
  - Edit `hosts/sugar/default.nix` to:
    1. Add `"forgejo"` to the `server.postgresql.databases` list (after "n8n", alphabetically)
    2. Add Forgejo enablement block:
       ```nix
       server.forgejo = {
         enable = true;
         dbHost = "127.0.0.1";
       };
       ```
    3. Verify Norish is still enabled (it should be, just on the new port 3100 from Task 2)
  - Run `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath` to validate

  **Must NOT do**:
  - Do NOT change any other service configurations
  - Do NOT modify PostgreSQL settings beyond adding "forgejo" to databases
  - Do NOT remove or modify the Norish config block

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small edits to an existing host config file
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sequential after Task 3)
  - **Blocks**: Tasks 5, 6
  - **Blocked By**: Tasks 1, 2, 3 (module, port fix, and secrets must all exist)

  **References**:

  **Pattern References**:
  - `hosts/sugar/default.nix:40-49` — The `server.postgresql` block where `databases` list lives. Add `"forgejo"` to this list.
  - `hosts/sugar/default.nix:51-54` — The `server.n8n` enablement block. Follow this exact pattern for Forgejo.

  **WHY Each Reference Matters**:
  - `postgresql` block — Shows exact format for adding a database name to the list
  - `n8n` block — Shows the canonical `server.<name> = { enable = true; dbHost = "..."; }` pattern on sugar

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Sugar nix eval succeeds
    Tool: Bash
    Preconditions: Tasks 1-3 completed, all files saved
    Steps:
      1. Run: nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath
    Expected Result: Returns a derivation path string (no error)
    Failure Indicators: Error message from nix eval
    Evidence: .sisyphus/evidence/task-4-sugar-eval.txt

  Scenario: Forgejo is enabled and database added
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Run: grep -c '"forgejo"' hosts/sugar/default.nix (in databases list)
      2. Run: grep -c "server.forgejo" hosts/sugar/default.nix
    Expected Result: Both return >= 1
    Failure Indicators: Either returns 0
    Evidence: .sisyphus/evidence/task-4-sugar-config.txt
  ```

  **Commit**: YES (groups with Tasks 5, 6)
  - Message: `feat(server): enable forgejo on sugar with caddy route`
  - Files: `hosts/sugar/default.nix`

- [ ] 5. Add Caddy Reverse Proxy Route on Psychosocial

  **What to do**:
  - Edit `hosts/psychosocial/default.nix` to add a Forgejo handler inside the existing `*.pytt.io` Caddy block
  - Add the handler following the existing pattern:
    ```
    @forgejo host forgejo.pytt.io git.pytt.io
    handle @forgejo {
      request_body {
        max_size 1G
      }
      reverse_proxy 10.10.30.111:3000
    }
    ```
  - The `request_body { max_size 1G }` directive is CRITICAL for Git LFS uploads — without it, large pushes fail with 413 errors
  - Match both `forgejo.pytt.io` and `git.pytt.io` in the host matcher (git.pytt.io is the primary, forgejo.pytt.io as alias)
  - Do NOT add `import authelia` — Forgejo uses its own auth
  - Run `nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath` to validate

  **Must NOT do**:
  - Do NOT add `import authelia` block (Forgejo uses built-in auth)
  - Do NOT modify any existing Caddy handlers
  - Do NOT change TLS or certificate settings

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Adding a handler block to existing Caddy config
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3
  - **Blocks**: Task 6
  - **Blocked By**: Task 4 (sugar config must be valid first)

  **References**:

  **Pattern References**:
  - `hosts/psychosocial/default.nix` — The existing Caddy `*.pytt.io` block with `@service host service.pytt.io` matchers. Add Forgejo handler following the same pattern. Look at services WITHOUT authelia (like those with `strip_header Remote-User`) since Forgejo handles its own auth.

  **WHY This Reference Matters**:
  - Must match the exact Caddyfile syntax used in the existing config. The handler position, indentation, and directive order must be consistent.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Psychosocial nix eval succeeds
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Run: nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath
    Expected Result: Returns a derivation path string (no error)
    Failure Indicators: Error message from nix eval
    Evidence: .sisyphus/evidence/task-5-psychosocial-eval.txt

  Scenario: Caddy config has forgejo handler
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Run: grep -c "git.pytt.io" hosts/psychosocial/default.nix
      2. Run: grep -c "10.10.30.111:3000" hosts/psychosocial/default.nix
      3. Run: grep -c "max_size" hosts/psychosocial/default.nix
    Expected Result: All return >= 1
    Failure Indicators: Any returns 0
    Evidence: .sisyphus/evidence/task-5-caddy-config.txt

  Scenario: No authelia import for forgejo
    Tool: Bash
    Preconditions: Task completed
    Steps:
      1. Extract the forgejo handler block from psychosocial/default.nix
      2. Verify it does NOT contain "import authelia"
    Expected Result: No authelia import in the forgejo handler
    Failure Indicators: authelia import found in forgejo block
    Evidence: .sisyphus/evidence/task-5-no-authelia.txt
  ```

  **Commit**: YES (groups with Task 4, 6)
  - Message: `feat(server): enable forgejo on sugar with caddy route`
  - Files: `hosts/psychosocial/default.nix`

- [ ] 6. Final Nix Eval Verification for Both Hosts

  **What to do**:
  - Run `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath` — must succeed
  - Run `nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath` — must succeed
  - Verify no port conflicts by checking the evaluated config
  - If either eval fails, diagnose and fix the issue before proceeding

  **Must NOT do**:
  - Do NOT proceed if either eval fails
  - Do NOT deploy (deployment is a user action after plan completion)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Running two nix eval commands and checking output
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (after Task 5)
  - **Blocks**: F1-F4
  - **Blocked By**: Tasks 4, 5

  **References**:

  **Pattern References**:
  - CLAUDE.md — `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` is the standard test eval command

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Both host evals succeed
    Tool: Bash
    Preconditions: All previous tasks completed
    Steps:
      1. Run: nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath
      2. Run: nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath
    Expected Result: Both return derivation path strings without errors
    Failure Indicators: Any error output from either command
    Evidence: .sisyphus/evidence/task-6-final-eval.txt

  Scenario: No other hosts broken
    Tool: Bash
    Preconditions: Both sugar and psychosocial pass
    Steps:
      1. Run: nix eval .#nixosConfigurations.pulse.config.system.build.toplevel.drvPath
      2. Run: nix eval .#nixosConfigurations.byob.config.system.build.toplevel.drvPath
    Expected Result: Both return derivation paths (unchanged hosts still valid)
    Failure Indicators: Any error — indicating the module change broke shared code
    Evidence: .sisyphus/evidence/task-6-other-hosts-eval.txt
  ```

  **Commit**: NO (verification task only — changes already committed in previous tasks)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, check config). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `nix eval` for sugar and psychosocial. Review all changed .nix files for: syntax correctness, option types match, proper `lib.mkIf`/`lib.mkEnableOption` usage, no hardcoded secrets, follows codebase naming conventions, proper sops integration. Check for AI slop: excessive comments, over-abstraction.
  Output: `Eval [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Execute EVERY QA scenario from EVERY task — run `nix eval` commands, verify secret structure, verify Caddy config syntax. Test cross-task integration: sugar config includes both forgejo enablement AND norish port change AND postgresql database addition. Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual changes. Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | VERDICT`

---

## Commit Strategy

- **Commit 1** (after Tasks 1-2): `feat(server): add forgejo module and move norish port` — modules/server/forgejo.nix, modules/server/default.nix, modules/server/norish.nix
- **Commit 2** (after Task 3): `chore(secrets): add forgejo secrets to sugar` — secrets/sugar.yaml
- **Commit 3** (after Tasks 4-6): `feat(server): enable forgejo on sugar with caddy route` — hosts/sugar/default.nix, hosts/psychosocial/default.nix

---

## Success Criteria

### Verification Commands
```bash
nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath
# Expected: derivation path (no errors)

nix eval .#nixosConfigurations.psychosocial.config.system.build.toplevel.drvPath
# Expected: derivation path (no errors)
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] Both nix eval commands succeed
- [ ] No port conflicts on sugar
- [ ] Module follows codebase conventions
- [ ] Secrets properly structured in sugar.yaml
