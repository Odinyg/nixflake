# Plan: Consume second-brain module from Brain flake input + deploy to nero

This plan covers the **nixflake side** of a larger Brain repo refactor. It's standalone — you don't need to read the Brain plan to execute this, but the "Context" section explains what's happening on the other side of the boundary.

The companion plan (executed in the Brain repo by a separate Claude session) lives at `Brain/.agent/plans/unify-brain-and-nix-module.md`.

## Context

**What's changing in the Brain repo (out of scope for this plan, but you should know):**
- `Brain` becomes a Nix flake exposing `nixosModules.default`
- `Brain/Memory/` is being extracted into a separate `brain-vault` repo (history preserved via `git filter-repo`)
- Vault sync moves from a hand-rolled bash script to vendored `simonthum/git-sync` + a `concat-both` custom merge driver
- A new `bootstrap` systemd service handles first-time clone of both repos, registers the merge driver, and provisions an SSH deploy key from sops

**What changes in nixflake (THIS plan):**
1. Add `brain` as a flake input pointing at the Brain repo on forgejo
2. Refactor `modules/server/default.nix` so it can import modules sourced from flake inputs
3. Replace the import of the locally-vendored `./second-brain.nix` with `inputs.brain.nixosModules.default`
4. Update `hosts/nero/default.nix` to enable `server.second-brain` with new options pointing at sugar's conduit (which stays put)
5. **Cutover**: disable `server.second-brain` on sugar (`hosts/sugar/default.nix:92`)
6. **Cleanup**: delete the now-orphaned `modules/server/second-brain.nix` after 24h soak
7. Update `CLAUDE.md`

**Migration target: nero** (`10.10.30.115`). Sugar keeps running everything else (Caddy, vaultwarden, freshrss, conduit/Matrix, etc.) unchanged. Conduit stays on sugar — nero's bot points across the LAN at `http://10.10.30.111:6167`. Conduit already binds `0.0.0.0` per `modules/server/matrix.nix:45`, so no firewall/proxy work is needed.

**Preconditions** (already complete per `plans/nero-bringup.md` Phases A–C):
- nero exists in `parts/hosts.nix` and `parts/deploy.nix`, evaluates, deploys
- nero is reachable on `10.10.30.115` with static IP
- `secrets/nero.yaml` exists with 9 of 10 second-brain secrets (the 10th — `second_brain_deploy_key` — gets added by you in task 5 of THIS plan)
- `.sops.yaml` has `&nero` anchor + creation rule
- nero's host config (`hosts/nero/default.nix`) does **not** yet have `server.second-brain` enabled

**Hard preconditions before you start (verify with the Brain Claude session before proceeding):**
- `Brain/flake.nix` exists on the forgejo `master` branch and exposes `nixosModules.default`
- `brain-vault` repo exists on forgejo at `git@git.pytt.io:odin/brain-vault.git`, populated with vault history + `.git-sync/git-sync` + `.git-sync/git-merge-concat` + `.gitattributes`
- A forgejo SSH deploy key has been generated; the **public half** is registered as a deploy key (write access) on BOTH `odin/Brain` and `odin/brain-vault`
- The **private half** is in your hands as a string ready to paste into `secrets/nero.yaml` in task 5

If any of these are missing, **stop and tell the user** — they need to run the Brain plan up to its task 16 first.

---

## Module options exposed by the new Brain flake

The Brain flake's `nixosModules.default` is largely the same as the current vendored `modules/server/second-brain.nix` but with new options for the two-repo split, bootstrap, and deploy key. When you wire it up in `hosts/nero/default.nix`, these are the options you'll set or override:

| Option | Default | What you set on nero |
|---|---|---|
| `enable` | `false` | `true` |
| `projectDir` | `/var/lib/second-brain` | `/home/odin/projects/Brain` |
| `vaultDir` | `/home/odin/projects/Brain-Vault` | (default OK) |
| `repoUrl` | `git@git.pytt.io:odin/Brain.git` | (default OK) |
| `vaultRepoUrl` | `git@git.pytt.io:odin/brain-vault.git` | (default OK) |
| `deployKeySecret` | `"second_brain_deploy_key"` | (default OK — references sops key by name) |
| `user` | `odin` | (default OK) |
| `matrix.homeserver` | `http://localhost:6167` | `http://10.10.30.111:6167` |
| `matrix.userId` | `@brain:pytt.io` | (default OK) |
| `matrix.notifyRoom` | `""` | `"!ExLmjhT_x3E2dLwnd1Ef3dgaWezPJC0-X6Oqk3Tcy_Q"` |
| `vaultSync.enable` | `true` | (default OK) |
| `vaultSync.calendar` | `*-*-* *:0/2:00` | (default OK — every 2 min) |
| `heartbeat.enable` / `.calendar` | enabled, every 30 min during 07-19 | (default OK) |
| `reflection.enable` / `.calendar` | enabled, daily 08:00 | (default OK) |

**Verify the option names match reality** before relying on this table — read `Brain/nix/module.nix` from the actual Brain commit you're pinning. The Brain plan may have renamed something.

---

## Tasks

Execute in order. Each task is atomic.

### 1. INSPECT Brain flake URL + verify reachability

- **IMPLEMENT**: Find the exact forgejo URL for the Brain repo. The other plans suggest `git+https://git.pytt.io/odin/Brain` or `git+ssh://git@git.pytt.io/odin/Brain`. HTTPS is simpler if forgejo allows anonymous read; SSH is required if not.
- **VALIDATE**: 
  ```bash
  nix flake metadata git+https://git.pytt.io/odin/Brain 2>&1 | head -10
  ```
  If this prints flake metadata, HTTPS works. If it errors with auth, you need SSH form: `git+ssh://git@git.pytt.io/odin/Brain` (or via the alias the user has in `~/.ssh/config`).
- **GOTCHA**: SSH form requires the user's SSH key to be loaded in their agent for `nix flake update brain` to work from workstation. The runtime sugar/nero deploy doesn't use this URL — only the workstation's `nix flake update` does.

### 2. ADD `brain` flake input to `nixflake/flake.nix`

- **IMPLEMENT**: Edit `nixflake/flake.nix`. Add a new input alongside the existing ones (after `colmena` is fine):
  ```nix
  brain = {
    url = "<URL from task 1>";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
  ```
- The `inputs.nixpkgs.follows` line aligns Brain's nixpkgs with the server tier (nero is a server, uses `nixpkgs-unstable` per `parts/lib.nix`). Without it, Brain pulls its own nixpkgs lock entry, which is wasteful.
- **VALIDATE**: 
  ```bash
  cd /home/none/nixflake
  nix flake metadata 2>&1 | grep -A 2 "brain"
  nix flake update brain
  cat flake.lock | python3 -c "import json,sys;print(json.load(sys.stdin)['nodes']['brain']['locked'])"
  ```
  Output should show a `rev` and `lastModified` for the Brain repo. Pin gets recorded in `flake.lock`.

### 3. REFACTOR `modules/server/default.nix` to import from flake input

- **IMPLEMENT**: Read `modules/server/default.nix` first to understand its current shape.
  - **If it's a static `imports = [ ./foo.nix ./bar.nix ./second-brain.nix ];` attrset**: convert it to a function `{ inputs, ... }: { imports = [ ./foo.nix ./bar.nix inputs.brain.nixosModules.default ]; }`. This is the standard pattern for accessing flake inputs inside a NixOS module.
  - **If it's already `{ inputs, ... }:` shaped**: just swap `./second-brain.nix` for `inputs.brain.nixosModules.default` in the imports list.
  - **Either way**: do NOT delete `./second-brain.nix` from disk yet. Leave it in place as a fallback. Only its import line is removed.
- **GOTCHA**: flake-parts threads `inputs` through automatically — this works as long as the consuming module is a function. If it isn't, the refactor is the conversion. Verify by reading other server modules (e.g., `modules/server/matrix.nix`) for the project's idiom.
- **VALIDATE**:
  ```bash
  nix flake check
  nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath
  ```
  Both should succeed. Sugar's config still references the (now-deleted-import) module via `server.second-brain.enable = true` in `hosts/sugar/default.nix:93`, so the new flake-input import must produce the same module schema. If sugar's eval breaks, the new module's option set is incompatible — see GOTCHA in task 4.

### 4. RESOLVE `inputs.claude-code` if check fails

- **IMPLEMENT**: The current `modules/server/second-brain.nix:99` does:
  ```nix
  inputs.claude-code.packages.${pkgs.system}.default
  ```
  When this same module is imported from `inputs.brain.nixosModules.default`, the `inputs` argument refers to **nixflake's** `outputs.inputs`, NOT Brain's. Nixflake already has `claude-code` as a top-level input, so this should work — but it depends on flake-parts threading `inputs` into the imported module's argument set.
  
  If `nix flake check` in task 3 fails with `attribute 'claude-code' missing`, the fix is one of:
  - **(a)** Pass `claude-code` via `_module.args` in `parts/hosts.nix` `mkServer` `specialArgs` (preferred — declarative, applies to all server hosts)
  - **(b)** Tell the Brain Claude session to refactor `Brain/nix/module.nix` to take `claude-code` as an explicit argument (`{ config, lib, pkgs, claude-code, ... }:`), then pass it from nixflake via `specialArgs.claude-code = inputs.claude-code.packages.${pkgs.system}.default;`
- **VALIDATE**: `nix flake check` passes; `nix eval .#nixosConfigurations.sugar.config.system.build.toplevel.drvPath` returns a path.

### 5. ADD deploy key to `secrets/nero.yaml`

- **PRECONDITION**: The Brain Claude session has handed you the **private** half of the forgejo deploy SSH key (an ed25519 PEM block starting `-----BEGIN OPENSSH PRIVATE KEY-----`). The **public** half is already registered as a deploy key with WRITE access on both `odin/Brain` and `odin/brain-vault` on forgejo.
- **IMPLEMENT**:
  ```bash
  cd /home/none/nixflake
  sops secrets/nero.yaml
  ```
  Add a new top-level key:
  ```yaml
  second_brain_deploy_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    <paste the full key including BEGIN/END markers, indented one level under the | block scalar>
    -----END OPENSSH PRIVATE KEY-----
  ```
  Save and exit (sops re-encrypts on close).
- **GOTCHA**: Multi-line YAML — the `|` block scalar is critical to preserve newlines. If you accidentally use `>` (folded scalar), the key will become a single line and SSH will reject it.
- **VALIDATE**:
  ```bash
  sops -d secrets/nero.yaml | grep -c second_brain_   # must return 10 (was 9)
  sops -d secrets/nero.yaml | grep -c "BEGIN OPENSSH" # must return 1
  ```

### 6. ENABLE `server.second-brain` in `hosts/nero/default.nix`

- **IMPLEMENT**: Edit `hosts/nero/default.nix`. Add the `server.second-brain` block (mirroring sugar's at `hosts/sugar/default.nix:92-98` but with the cross-host conduit URL and the new `vaultDir` option if it's not at its default — defaults are fine, so vaultDir can be omitted):
  ```nix
  server.second-brain = {
    enable = true;
    projectDir = "/home/odin/projects/Brain";
    matrix.homeserver = "http://10.10.30.111:6167";   # sugar's conduit, across LAN
    matrix.userId = "@brain:pytt.io";
    matrix.notifyRoom = "!ExLmjhT_x3E2dLwnd1Ef3dgaWezPJC0-X6Oqk3Tcy_Q";
  };
  ```
  Place it next to other `server.*.enable` entries if any exist, or at the end of the host's config block.
- **GOTCHA**: Do NOT also enable services nero doesn't need (postgresql, n8n, etc.). Sugar enables many services in `hosts/sugar/default.nix` — none of those move to nero. Only `server.second-brain`.
- **VALIDATE**:
  ```bash
  nix flake check
  nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath
  nix eval --raw .#nixosConfigurations.nero.config.systemd.services.second-brain-bot.serviceConfig.ExecStart
  nix eval --raw .#nixosConfigurations.nero.config.systemd.services.second-brain-vault-sync.serviceConfig.ExecStart
  ```
  All should succeed. The two ExecStart strings should reference paths under `/home/odin/projects/Brain` and `/home/odin/projects/Brain-Vault` respectively.

### 7. CAPTURE pre-deploy state on sugar (for diff)

- **IMPLEMENT**: 
  ```bash
  ssh odin@sugar 'systemctl is-active second-brain-bot second-brain-heartbeat second-brain-vault-sync' > /tmp/sugar-pre-deploy.txt 2>&1
  ssh odin@sugar 'systemctl list-timers "second-brain-*" --no-pager' >> /tmp/sugar-pre-deploy.txt
  ```
  This captures sugar's current state. We'll diff after the sugar disable in task 11.
- **VALIDATE**: File is non-empty.

### 8. COMMIT nixflake changes (pre-deploy)

- **IMPLEMENT**: Single commit (no Co-Authored-By per nixflake CLAUDE.md):
  ```bash
  cd /home/none/nixflake
  git status   # confirm only the expected files
  git diff
  git add flake.nix flake.lock modules/server/default.nix hosts/nero/default.nix secrets/nero.yaml
  git commit -m "feat(nero): consume second-brain from Brain flake input, enable on nero"
  ```
- The vendored `modules/server/second-brain.nix` is intentionally NOT touched in this commit — it stays on disk as a fallback until task 12.
- **VALIDATE**: `git status` clean. `git log -1 --stat` shows the expected files.

### 9. DEPLOY to nero

- **IMPLEMENT**:
  ```bash
  cd /home/none/nixflake
  git status   # MUST be clean (colmena requires it per nixflake CLAUDE.md)
  just deploy nero
  ```
  Watch for evaluation errors first, then activation errors.
- **VALIDATE** (immediately after deploy returns success):
  ```bash
  ssh odin@nero 'systemctl is-active second-brain-bootstrap second-brain-venv second-brain-bot'
  ssh odin@nero 'systemctl list-timers "second-brain-*" --no-pager'
  ssh odin@nero 'ls -la /home/odin/projects/Brain/.git /home/odin/projects/Brain-Vault/.git'
  ssh odin@nero 'git -C /home/odin/projects/Brain-Vault config --get merge.concat-both.driver'
  ssh odin@nero 'test -f /home/odin/.ssh/brain_deploy && echo "Deploy key present"'
  ssh odin@nero 'systemctl show second-brain-bot -p Environment | grep VAULT_DIR'
  ```
  Every command must produce sensible output. If the bootstrap service fails, `journalctl -u second-brain-bootstrap` on nero will explain why — most likely the deploy key doesn't authenticate to forgejo (check task 5's key, check that you ticked "write access" on both forgejo deploy key entries).

### 10. WAIT for first vault-sync tick + verify round-trip

- **IMPLEMENT**: Wait ~3 minutes. Then on workstation:
  ```bash
  cd /home/none/projects/Brain-Vault   # workstation clone, set up by Brain Claude session in M2
  git pull
  cat HEARTBEAT.md   # or daily/$(date +%Y-%m-%d).md
  ```
  And on nero:
  ```bash
  ssh odin@nero 'journalctl -u second-brain-vault-sync --since "5 min ago" --no-pager | tail -20'
  ```
- **VALIDATE**:
  - Workstation pulls without error
  - Recent vault-sync log entries on nero show "Vault sync OK" (or git-sync's success output)
  - HEARTBEAT.md or today's daily log contains entries that originated on nero post-deploy

### 11. END-TO-END test the bot + cutover sugar

- **IMPLEMENT**:
  - From a Matrix client, DM the bot. Ask "what host are you running on?" or "what's in HEARTBEAT.md?"
  - Bot should reply within ~30s
  - **Critical**: at this moment TWO bots are running (sugar's old one + nero's new one) and racing. You may get one or two responses. This is fine for a brief soak window — proceed to disable sugar promptly.
  - Edit `hosts/sugar/default.nix:93`: change `enable = true;` to `enable = false;`
  - Commit: "chore(sugar): disable second-brain (migrated to nero)"
  - `cd /home/none/nixflake && just deploy sugar`
- **VALIDATE**:
  - `ssh odin@sugar 'systemctl list-units --all "second-brain-*"'` shows no active or loaded units
  - `ssh odin@sugar 'systemctl list-timers | grep second-brain'` returns empty
  - DM the Matrix bot — exactly ONE response (from nero, not racing anymore)
  - `ssh odin@sugar 'ls /home/odin/projects/Brain'` — directory still exists on disk (intentional — backup for ~1 week)
- **GOTCHA**: If you get NO response to the Matrix DM after disabling sugar, nero's bot can't reach sugar's conduit. Debug with:
  ```bash
  ssh odin@nero 'curl -v http://10.10.30.111:6167/_matrix/client/versions'
  ```
  If this fails, check sugar's matrix module binds `0.0.0.0` (it should, per `modules/server/matrix.nix:45`) and that no firewall is blocking (homelab servers have firewall off per CLAUDE.md).

### 12. DELETE vendored module (after 24h soak)

- **PRECONDITION**: 24h elapsed since task 11 with the bot, vault-sync, heartbeat, and reflection all green on nero.
- **IMPLEMENT**:
  ```bash
  cd /home/none/nixflake
  rm modules/server/second-brain.nix
  git add -A
  git commit -m "chore(server): remove vendored second-brain.nix, sourced from Brain flake input"
  ```
- **VALIDATE**:
  - `nix flake check` passes
  - `nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath` returns the same path it did before the deletion (no functional change — the file was already orphaned)
  - Re-deploy as a sanity check: `just deploy nero` — should be a no-op activation

### 13. UPDATE `nixflake/CLAUDE.md`

- **IMPLEMENT**: Add a brief note in an appropriate section (probably under "Hosts" or as a new "External modules" section):
  > **second-brain module**: sourced from the `brain` flake input (Brain repo on forgejo), not vendored locally. To upgrade module schema: `nix flake update brain && just deploy nero`. The module deploys to `nero` (10.10.30.115); sugar previously hosted it but was migrated.
- Also update the "Hosts" section to note that nero exists and runs second-brain.
- **VALIDATE**: Read the diff. No false claims about file paths.

---

## Validation summary

After all tasks:
- [ ] `nixflake/flake.nix` has `brain` input, locked in `flake.lock`
- [ ] `nixflake/modules/server/default.nix` imports `inputs.brain.nixosModules.default` instead of `./second-brain.nix`
- [ ] `nixflake/modules/server/second-brain.nix` deleted
- [ ] `hosts/nero/default.nix` has `server.second-brain.enable = true` with cross-host conduit URL
- [ ] `hosts/sugar/default.nix:93` has `enable = false`
- [ ] `secrets/nero.yaml` has 10 second-brain secrets including `second_brain_deploy_key`
- [ ] `nix flake check` passes
- [ ] `just deploy nero` succeeds; bootstrap, venv, bot, heartbeat, reflection, vault-sync all healthy
- [ ] `just deploy sugar` succeeds; no `second-brain-*` units active on sugar
- [ ] Matrix bot responds to a DM (single response, from nero)
- [ ] Vault round-trip works: nero writes to a daily log, workstation pulls it within 2 min
- [ ] `nixflake/CLAUDE.md` updated

---

## Risks + rollback

| Task | Risk | Rollback |
|---|---|---|
| 3 (refactor default.nix) | Wrong refactor breaks all server hosts | One-line revert restores `./second-brain.nix` import |
| 4 (claude-code arg) | Brain module needs fixing on the other side | Coordinate with Brain Claude session — don't proceed with task 6+ until check passes |
| 6 (enable on nero) | Wrong matrix.homeserver URL → bot can't reach conduit | Bot fails on startup with clear error in journal; fix URL, redeploy |
| 9 (deploy nero) | Bootstrap fails on `git clone` due to bad/missing deploy key | Check `journalctl -u second-brain-bootstrap` on nero; fix key in sops; `systemctl restart second-brain-bootstrap` |
| 11 (cutover sugar) | Nero bot can't reach conduit, sugar bot already disabled → no bot at all | Re-enable sugar (`enable = true` → redeploy), debug nero→sugar reachability separately |
| 12 (delete vendored) | None — file is already orphaned from imports | `git revert` if needed |

**Highest-risk task**: 9. The deploy key is a single point of failure for the bootstrap. Verify with `ssh odin@nero 'sudo -u odin git -C /tmp ls-remote git@git.pytt.io:odin/brain-vault.git'` (or similar) BEFORE running the deploy if you want extra confidence — though this requires the key to already be in `/home/odin/.ssh/brain_deploy`, which only happens after deploy. Catch-22; just trust the deploy and check journal if it fails.

---

## What's NOT in this plan

- **Generating the deploy keypair**: handled by the Brain Claude session (Brain plan task 10)
- **Adding the public key to forgejo**: manual one-time step the user does
- **Creating the brain-vault repo on forgejo**: handled by Brain plan
- **Writing `Brain/nix/module.nix` and `Brain/flake.nix`**: handled by Brain plan
- **Bootstrap script semantics, vault-sync internals, merge driver**: implemented in `Brain/nix/module.nix`, owned by Brain plan
- **Workstation setup of `Brain-Vault` clone**: handled by Brain plan
- **Removing `Brain/Memory/` from the Brain code repo**: handled by Brain plan after 24h soak

This plan ONLY touches files inside `/home/none/nixflake`. Anything in `/home/none/projects/Brain` is the Brain Claude session's responsibility.

---

## Coordination points with Brain Claude session

You will need to pause and coordinate at these points:

| Pause point | Need from Brain session | What to check before resuming |
|---|---|---|
| Before task 1 | Brain repo has `flake.nix` exposing `nixosModules.default`, pushed to forgejo | `nix flake metadata git+https://git.pytt.io/odin/Brain` returns metadata listing `nixosModules.default` |
| Before task 5 | Forgejo deploy key generated; private half ready to paste; public half registered on both `odin/Brain` and `odin/brain-vault` with write access | Ask the user to confirm both deploy keys show in forgejo UI with the write checkbox |
| Before task 9 | `brain-vault` repo exists on forgejo, populated with vault history + `.git-sync/` + `.gitattributes` | `git ls-remote git@git.pytt.io:odin/brain-vault.git master` returns a hash |
| After task 11 (sugar disabled) | Brain session can proceed to its task 32 (delete `Brain/Memory/` from code repo) — they're waiting on this | Tell the Brain session "sugar is off, you can proceed" |
