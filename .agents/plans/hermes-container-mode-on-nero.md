# Feature: Switch hermes-agent on nero to NixOS container (podman) mode

The following plan should be complete, but its important that you validate documentation and codebase patterns and task sanity before you start implementing.

## Feature Description

Migrate `services.hermes-agent` on host **nero** from native NixOS mode (uv2nix-built python venv with a `PYTHONPATH` wrapper hack to inject `matrix-nio`) to the upstream-supported **container mode** (`services.hermes-agent.container.enable = true`), running an Ubuntu 24.04 OCI image under **podman**. The host stays declaratively managed by nix; only the hermes runtime moves into a writable container layer where `pip install`, skill installs, and self-modification work the way upstream expects.

This is **step 1** of a two-step migration discussed with the user. Step 2 (full Ubuntu VM + docker-compose) is out of scope for this plan.

## User Story

As the operator of nero
I want hermes-agent to run inside its upstream Ubuntu container under podman
So that matrix-nio, skills, and future python deps install cleanly without nix wrapper hacks, while the rest of the host stays declarative

## Problem Statement

The current native deployment fights NixOS in three structural ways:

1. **matrix-nio injection** requires a `symlinkJoin` + `wrapProgram --prefix PYTHONPATH` against a separate `python311.withPackages` env from stable nixpkgs (see `hosts/nero/default.nix:54-87`). Every additional optional dep would need the same dance.
2. **Skills install at runtime** mix `/nix/store` (immutable) and `/var/lib/hermes` (mutable) — fragile.
3. **systemd hardening** in the upstream module conflicts with hermes' self-modification expectations.

## Solution Statement

Flip the upstream module's container switch. The module already ships `services.hermes-agent.container.{enable,backend,image,extraVolumes,extraOptions}` (verified by `nix eval` against the live `nero` config — see Phase 2 notes below). Set `backend = "podman"`, mount the read-only Brain vault into the container, drop the matrix wrapper, and enable `virtualisation.podman` on nero. After first start, install matrix-nio inside the container's writable layer with one `podman exec ... pip install matrix-nio` — it persists across restarts because the writable layer lives under `/var/lib/hermes`.

## Feature Metadata

**Feature Type**: Refactor (deployment topology change)
**Estimated Complexity**: Low
**Primary Systems Affected**: `hosts/nero/default.nix`, nero runtime (adds podman)
**Dependencies**: `virtualisation.podman` (NixOS built-in), upstream `inputs.hermes-agent` flake (already pinned), Ubuntu 24.04 image pulled at runtime

---

## CONTEXT REFERENCES

### Relevant Codebase Files — READ BEFORE IMPLEMENTING

- `hosts/nero/default.nix` (entire file, 153 lines) — Why: this is the only file being changed. Pay attention to:
  - lines 49-52: sops `hermes-env` secret declaration (must keep, container reads it via `environmentFiles`)
  - lines 54-87: the `package = symlinkJoin { ... wrapProgram ... matrix-nio }` block — **DELETE entirely**
  - lines 59-96: `services.hermes-agent` settings block — keep `enable`, `addToSystemPackages`, `environmentFiles`, `environment`, `settings`, `documents`; ADD container sub-block
  - lines 71-74: `OBSIDIAN_VAULT_PATH = "/var/lib/hermes/vault"` — this path must be valid **inside the container**. The container's `stateDir` (`/var/lib/hermes`) is bind-mounted from the host by the upstream module, so the vault subdirectory is visible to both sides without further work.
  - lines 137-150: tmpfiles + bind-mount of `/home/odin/projects/Brain-Vault` → `/var/lib/hermes/vault` (read-only) — KEEP AS-IS. The host bind-mount sits inside `stateDir`, which the container mounts wholesale, so the vault appears at the same path inside the container.
- `flake.nix:33-36` — `inputs.hermes-agent` pin (`github:NousResearch/hermes-agent`). Confirms the module providing `container.*` options is the same one already imported on line 11 of nero.
- `CLAUDE.md` — note the **commit-before-colmena** rule and the "servers use nixpkgs-unstable" rule.

### New Files to Create

None. Single-file edit.

### Relevant Documentation — READ BEFORE IMPLEMENTING

- NixOS manual — [virtualisation.podman](https://nixos.org/manual/nixos/unstable/options#opt-virtualisation.podman.enable)
  - Why: enabling podman on a server that currently has neither docker nor podman; need `dockerCompat` consideration
- Upstream hermes-agent flake `nixosModules.default` — inspect via `nix eval .#nixosConfigurations.nero.options.services.hermes-agent.container` (verified options listed in Phase 2 of this plan)
- Previous related work: `.claude/plans/archive/hermes-on-nero.md` — original deployment plan, useful for context on why nero hosts hermes at all

### Patterns to Follow

**Module style** — `hosts/nero/default.nix` uses direct `services.<name> = { ... }` blocks, no extra abstraction. Keep that.

**Server hardening** — nero is a `mkServer` host (no home-manager, no stylix). Don't import desktop modules.

**Podman on a server** — there is currently no other server in this flake running podman/docker (verified: `grep -r 'virtualisation.podman\|virtualisation.docker' modules/server hosts` returns nothing relevant). This will be the first. Keep the enablement minimal:
```nix
virtualisation.podman = {
  enable = true;
  dockerCompat = false;   # nothing needs the docker CLI shim
  defaultNetwork.settings.dns_enabled = true;
};
```

**Verified upstream container sub-options** (from `nix eval` against the live module):
- `services.hermes-agent.container.enable` : bool — "Whether to enable OCI container mode (Ubuntu base, full self-modification support)."
- `services.hermes-agent.container.backend` : `"docker" | "podman"` — default `"docker"`
- `services.hermes-agent.container.image` : string — default `"ubuntu:24.04"`
- `services.hermes-agent.container.extraVolumes` : list of string — `host:container:mode` format
- `services.hermes-agent.container.extraOptions` : list of string — passed to `docker/podman run`

**Verified preserved options** (still apply in container mode):
- `enable`, `addToSystemPackages`, `environmentFiles`, `environment`, `settings`, `documents`, `stateDir` (default `/var/lib/hermes`), `user`, `group`

---

## IMPLEMENTATION PLAN

### Phase 1: Foundation — enable podman on nero

Add `virtualisation.podman.enable = true;` to `hosts/nero/default.nix`. No reboot needed; podman is a userland runtime.

### Phase 2: Flip hermes to container mode

In the same file, inside `services.hermes-agent`:

1. **Delete** the `let ... matrixEnv ... in` wrapper and the `package = pkgs.symlinkJoin { ... }` attribute (lines ~59-87 + 75-87). The container image carries its own python; the wrapper is meaningless inside it.
2. **Add** `container = { enable = true; backend = "podman"; };`
3. The vault is already inside `stateDir` (`/var/lib/hermes/vault`) via the existing host bind-mount, so **no `extraVolumes` entry is needed** — the upstream module mounts `stateDir` wholesale. Verify this assumption by reading the rendered systemd unit after first deploy; if the upstream module does NOT mount `stateDir` automatically, add `extraVolumes = [ "/var/lib/hermes/vault:/var/lib/hermes/vault:ro" ]`.

### Phase 3: First-boot integration — install matrix-nio in the writable layer

After deploy, run once on nero:

```sh
sudo podman exec hermes-agent pip install --break-system-packages matrix-nio
sudo systemctl restart hermes-agent
```

The install lands in the container's overlay/writable layer (or in `/var/lib/hermes` if upstream's image stores site-packages there — verify with `podman exec hermes-agent python -c 'import nio; print(nio.__file__)'`). If it lands in an ephemeral layer, add a small `ExecStartPost` script or a `postStart` hook in `extraOptions`. **Do not** re-introduce the nix wrapper.

### Phase 4: Validation

- `hermes-agent.service` reaches `active (running)`
- `podman ps` shows `hermes-agent` container Up
- Inside the container: `python -c 'import nio'` succeeds
- Vault visible: `podman exec hermes-agent ls /var/lib/hermes/vault | head` shows Brain vault contents
- Smoke-test matrix: hermes responds in its matrix room (`@hermes:pytt.io`)

---

## STEP-BY-STEP TASKS

Execute every task in order, top to bottom.

### UPDATE `hosts/nero/default.nix` — add podman

- **IMPLEMENT**: Insert `virtualisation.podman = { enable = true; dockerCompat = false; defaultNetwork.settings.dns_enabled = true; };` near the top of the module body (after the `networking` block is fine).
- **PATTERN**: same direct-attribute style as existing `server.disko`, `server.second-brain` blocks.
- **IMPORTS**: none beyond what's already imported.
- **GOTCHA**: nero currently has neither docker nor podman — this adds ~200MB closure. Acceptable per user discussion.
- **VALIDATE**: `nix eval .#nixosConfigurations.nero.config.virtualisation.podman.enable` → `true`

### UPDATE `hosts/nero/default.nix` — remove matrix-nio wrapper

- **REMOVE**: the `let upstream = ...; pkgs-stable = ...; matrixEnv = ...; in` prelude on the `services.hermes-agent` assignment, **and** the `package = pkgs.symlinkJoin { ... };` attribute inside the set. Convert `services.hermes-agent = let ... in { ... };` back to a plain `services.hermes-agent = { ... };`.
- **GOTCHA**: leave `addToSystemPackages = true;` — handy for `hermes` CLI on the host even with container mode.
- **VALIDATE**: `nix eval .#nixosConfigurations.nero.config.services.hermes-agent.package` still resolves (defaults to upstream package); no eval errors.

### ADD `hosts/nero/default.nix` — container sub-block

- **IMPLEMENT**: Inside `services.hermes-agent = { ... };`, add:
  ```nix
  container = {
    enable = true;
    backend = "podman";
  };
  ```
- **PATTERN**: sibling of `enable`, `settings`, `documents`.
- **GOTCHA**: do NOT also set `container.extraVolumes` for the vault on the first pass — the vault path lives under `stateDir` which the upstream module is expected to mount. Verify after deploy; only add `extraVolumes` if the post-deploy check shows the vault missing inside the container.
- **VALIDATE**: `nix eval .#nixosConfigurations.nero.config.services.hermes-agent.container.enable` → `true`

### VALIDATE eval & format

- **VALIDATE**: `nix fmt` (project uses nixfmt-rfc-style — see `parts/dev.nix`)
- **VALIDATE**: `nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath` (must succeed with no errors)

### COMMIT before colmena

- **IMPLEMENT**: `git add -A hosts/nero/default.nix && git commit -m "feat(hermes): switch to podman container mode on nero"`
- **GOTCHA**: CLAUDE.md mandates commit-before-colmena; deploy will refuse otherwise. NO Co-Authored-By line.
- **VALIDATE**: `git status` clean.

### DEPLOY nero

- **IMPLEMENT**: `just deploy nero`
- **GOTCHA**: first deploy will pull `ubuntu:24.04` (~80MB) at service start; expect a slower-than-usual first hermes-agent startup. Watch `journalctl -u hermes-agent -f` on nero.
- **VALIDATE**: `ssh odin@10.10.30.115 systemctl status hermes-agent` → `active (running)`

### POST-DEPLOY — install matrix-nio in container

- **IMPLEMENT**: 
  ```sh
  ssh odin@10.10.30.115 'sudo podman exec hermes-agent pip install --break-system-packages matrix-nio && sudo systemctl restart hermes-agent'
  ```
- **GOTCHA**: if the writable layer is ephemeral (i.e. `python -c 'import nio'` fails after restart), the install needs to live in `stateDir`. In that case: add a `systemd.services.hermes-agent.serviceConfig.ExecStartPost` (or upstream-supplied hook) that runs the pip install on every start, OR pre-bake a sidecar Containerfile. Defer the decision until the first restart proves the failure mode.
- **VALIDATE**: 
  - `ssh odin@10.10.30.115 'sudo podman exec hermes-agent python -c "import nio; print(nio.__version__)"'`
  - `ssh odin@10.10.30.115 'sudo podman exec hermes-agent ls /var/lib/hermes/vault | head'` shows Brain vault files
  - In matrix, send `@hermes:pytt.io ping` and confirm a reply

---

## TESTING STRATEGY

This is infrastructure-as-code with no test framework. Validation = `nix eval` + post-deploy smoke tests.

### Edge Cases to Verify Manually

- Vault mount: visible inside container, **read-only** (`podman exec hermes-agent touch /var/lib/hermes/vault/x` must fail)
- matrix-nio survives a `systemctl restart hermes-agent`
- matrix-nio survives a `systemctl restart` of the **host** (i.e. container recreate). If it doesn't, escalate per the "POST-DEPLOY" gotcha.
- Sops env file (`hermes-env`) is readable inside the container — the upstream module is responsible for wiring `environmentFiles` into `--env-file` on the podman invocation; verify with `podman inspect hermes-agent | grep -i env` if hermes can't reach its API key.

---

## VALIDATION COMMANDS

### Level 1: Syntax & Style

```sh
nix fmt
```

### Level 2: Eval

```sh
nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.nero.config.services.hermes-agent.container.enable
nix eval .#nixosConfigurations.nero.config.virtualisation.podman.enable
```

### Level 3: Deploy

```sh
git status   # MUST be clean
just deploy nero
```

### Level 4: Runtime smoke tests

```sh
ssh odin@10.10.30.115 'systemctl is-active hermes-agent && sudo podman ps --filter name=hermes-agent'
ssh odin@10.10.30.115 'sudo podman exec hermes-agent ls /var/lib/hermes/vault | head'
ssh odin@10.10.30.115 'sudo podman exec hermes-agent python -c "import nio; print(nio.__version__)"'
# matrix end-to-end:
#   send "@hermes:pytt.io ping" in the hermes room and confirm a response
```

---

## ACCEPTANCE CRITERIA

- [ ] `services.hermes-agent.container.enable = true` with `backend = "podman"` on nero
- [ ] `virtualisation.podman.enable = true` on nero
- [ ] The `symlinkJoin`/`wrapProgram`/`matrixEnv` block is gone from `hosts/nero/default.nix`
- [ ] `just deploy nero` succeeds with a clean git tree
- [ ] `hermes-agent.service` is `active (running)` post-deploy
- [ ] `podman exec hermes-agent python -c 'import nio'` succeeds
- [ ] Brain vault visible at `/var/lib/hermes/vault` inside the container, read-only
- [ ] hermes responds to a matrix ping in its room
- [ ] No regressions to `server.second-brain` (Brain agent) on the same host

---

## COMPLETION CHECKLIST

- [ ] All tasks completed in order
- [ ] `nix fmt` applied
- [ ] `nix eval` of toplevel drv succeeds
- [ ] Commit made before deploy (no Co-Authored-By)
- [ ] `just deploy nero` succeeded
- [ ] All Level 4 smoke tests pass
- [ ] matrix-nio persistence verified across at least one `systemctl restart hermes-agent`
- [ ] Acceptance criteria all met

---

## NOTES

**Why podman, not docker**: nero has neither today; podman is rootless-capable, daemonless, and the NixOS-idiomatic choice. The upstream module supports both via `container.backend`.

**Why not also pre-bake matrix-nio into a custom image now**: keeping the first migration minimal. If the post-deploy `pip install` doesn't persist, the next iteration is a tiny `Containerfile` (FROM `ubuntu:24.04`, RUN apt + pip install matrix-nio) built via `pkgs.dockerTools` or just `podman build` on nero. Defer until proven necessary.

**Step 2 is explicitly out of scope** — that's the full Ubuntu VM + docker-compose migration. Only execute it if container mode on nero turns out to also fight us.

**Rollback**: `git revert` the commit and `just deploy nero`. The native-mode wrapper and bind-mount stay valid; nothing is destructively migrated. The `/var/lib/hermes` state directory is reused by both modes.

**Confidence**: 7/10 for one-pass success. Main unknowns: (a) whether the upstream module auto-mounts `stateDir` into the container (likely yes, but unverified — addressed by the extraVolumes fallback), (b) whether `pip install` inside the container persists across restarts vs. requiring a hook (addressed by the POST-DEPLOY gotcha + escalation path).
