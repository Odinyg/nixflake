# Feature: Deploy hermes-agent on nero (Matrix gateway, ollama backend)

> Validate documentation links and the upstream `hermes-agent` flake's actual option names before implementing — the docs reference here is from 2026-04-08 and the project moves fast.

## Feature Description

Stand up [hermes-agent](https://github.com/NousResearch/hermes-agent) as a second always-on assistant on `nero`, alongside the existing `second-brain` Matrix bot. Hermes uses station's local **Ollama** instance (`gemma4:27b` on the 3090) as its LLM backend and connects to the existing pytt.io Conduit homeserver as a new Matrix user `@hermes:pytt.io`, responding only in a dedicated room.

This is a **homelab** deployment — single host, single user, no high-availability, no CI. "One-pass success" here means: `just deploy nero` brings the service up green, `hermes` CLI works on nero, and pinging `@hermes` in the dedicated room gets a reply routed through ollama.

## User Story

As Mr.No (homelab operator)
I want a second declarative AI agent running on nero, fully local-LLM-backed, on its own Matrix room
So that I can experiment with hermes' capabilities without touching the second-brain bot or paying API fees, and so the agent runs even when station's GPU is the only thing online.

## Problem Statement

- The existing second-brain bot (`@brain:pytt.io`) uses Anthropic API and is tightly scoped to vault management.
- I want a second agent for general experimentation that runs on **local** inference (gemma4:27b on the 3090), not paid APIs.
- It must coexist with second-brain on nero, not replace it, and be fully declarative via NixOS.

## Solution Statement

Add the `hermes-agent` flake input to `~/nixflake`, import its NixOS module, configure it inline in `hosts/nero/default.nix` to:
- Run **native** (hardened systemd, no container).
- Point `model.base_url` at `https://10.10.10.10:11434/v1` (station's ollama).
- Trust station's self-signed TLS cert system-wide on nero via `security.pki.certificateFiles`.
- Use the Matrix gateway transport with credentials for a new `@hermes:pytt.io` user, locked to a single room.
- Seed a fresh `SOUL.md` distinct from the second-brain bot's persona.
- Add `hermes` CLI to system PATH so `ssh nero` + `hermes` shares state with the gateway service.

## Feature Metadata

- **Feature Type**: New Capability
- **Estimated Complexity**: Medium (mostly wiring; one real risk: Matrix transport + self-signed TLS)
- **Primary Systems Affected**: `~/nixflake/flake.nix`, `~/nixflake/hosts/nero/default.nix`, `~/nixflake/secrets/nero.yaml`, station ollama (model pull), sugar conduit (user registration)
- **Dependencies**:
  - `github:NousResearch/hermes-agent` flake
  - Existing `services.ollama` on station (`modules/nixos/ollama.nix`)
  - Existing conduit homeserver on sugar (`10.10.30.111:6167`)
  - `sops-nix` (already configured for nero)

---

## CONTEXT REFERENCES

### Relevant Codebase Files — READ THESE FIRST

- `~/nixflake/flake.nix` (whole file, 45 lines) — flake input pattern; note `nixpkgs-unstable.follows` style used by `brain` input.
- `~/nixflake/hosts/nero/default.nix` (whole file, 42 lines) — current nero config; `server.second-brain` block at lines 29–39 is the only "service" here. Add hermes config alongside it.
- `~/nixflake/parts/hosts.nix` (lines 69–71) — `nero = mkServer { hostPath = ../hosts/nero; };` — nothing to change, just confirms how nero is wired.
- `~/nixflake/parts/lib.nix` (lines 74–91, esp. line 89) — `serverModules`; auto-loads `secrets/<hostname>.yaml`. Confirms hermes secret will be picked up by adding it to `secrets/nero.yaml`.
- `~/nixflake/modules/nixos/ollama.nix` (whole file, 51 lines) — station's ollama config. Self-signed cert at `/var/lib/ollama/tls/cert.pem` on station, SAN includes `IP:10.10.10.10`. Listens on `0.0.0.0:11434` HTTPS, `openFirewall = true`.
- `~/nixflake/hosts/station/default.nix` (line 38, line 204) — station IP `10.10.10.10`, `ollama.enable = true`.
- `~/nixflake/hosts/psychosocial/default.nix` (line 310) — caddy reverse-proxies `https://10.10.10.10:11434` for the public HTTPS path. Not used in this plan but documented as fallback.
- `~/projects/Brain/nix/modules/second-brain/default.nix` (lines 196–212) — sops secret declaration pattern (`sops.secrets.<name> = { owner; mode; path; }`) and SSH `extraConfig` style. **Mirror this pattern** for the `hermes-env` secret.
- `~/projects/Brain/nix/modules/second-brain/bot.nix` — read it once to see how the existing bot's matrix config is structured (informational; no changes here).
- `~/nixflake/secrets/nero.yaml` — current sops file; add a `hermes-env` key.
- `~/nixflake/justfile` — confirms `just deploy nero` is the deploy command.

### New Files to Create

- **None.** Everything is inline edits to existing files plus a new sops secret entry. (Optional: a `hosts/nero/hermes-soul.md` if you want SOUL.md tracked in-repo instead of inlined as a string.)

### Relevant Documentation — READ BEFORE IMPLEMENTING

- [Hermes Nix Setup](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup) — full module option reference. Key options used here: `enable`, `settings.model.{base_url,default}`, `environmentFiles`, `addToSystemPackages`, `documents`, `container.enable = false` (default).
- [Hermes Matrix transport](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/matrix) — env vars `MATRIX_HOMESERVER`, `MATRIX_USER_ID`, `MATRIX_PASSWORD` (or `MATRIX_ACCESS_TOKEN`), `MATRIX_ALLOWED_USERS`, `MATRIX_REQUIRE_MENTION`, `MATRIX_FREE_RESPONSE_ROOMS`, `MATRIX_HOME_ROOM`, `MATRIX_ENCRYPTION`. Yaml-side block: `matrix.{require_mention,free_response_rooms,auto_thread}`.
- [Hermes messaging overview](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/) — confirms Matrix is supported.
- [Ollama OpenAI compatibility](https://github.com/ollama/ollama/blob/main/docs/openai.md) — `/v1/chat/completions` etc. OpenAI client needs an API key string but ollama ignores its value. Use any non-empty string.
- [NixOS `security.pki.certificateFiles`](https://nixos.org/manual/nixos/stable/options#opt-security.pki.certificateFiles) — how to trust station's self-signed cert on nero.
- [Conduit user registration](https://docs.conduit.rs/registration.html) — for creating `@hermes:pytt.io`.

### Patterns to Follow

**sops secret declaration** — copy the shape from `Brain/nix/modules/second-brain/default.nix:196–200`:
```nix
sops.secrets."hermes-env" = {
  owner = "hermes";
  mode = "0400";
  # path is auto-derived; let sops put it under /run/secrets
};
```

**Inline service config in hosts/nero/default.nix** — mirror the existing `server.second-brain = { … };` block at lines 29–39. Place the new `services.hermes-agent = { … };` block right below it.

**Flake input style** — copy `brain` input shape from `flake.nix:29–32`:
```nix
hermes-agent = {
  url = "github:NousResearch/hermes-agent";
  inputs.nixpkgs.follows = "nixpkgs-unstable";
};
```
(Following `nixpkgs-unstable` matches what `brain` does and avoids 25.05 channel skew.)

**Module import** — flake-parts wires inputs through `specialArgs.inputs`. Inside `hosts/nero/default.nix`, accept `inputs` in the function args and reference `inputs.hermes-agent.nixosModules.default` in `imports`.

---

## IMPLEMENTATION PLAN

### Phase 0: Prerequisites (one-time, outside Nix)

These must be done **before** the first `just deploy nero`, otherwise the service will fail to start.

1. **Pull the model on station.**
   ```sh
   ollama pull gemma4:27b
   ollama list   # confirm it shows up, ~17 GB on a 3090 at q4
   ```
   Adjust the tag if `gemma4:27b` isn't the canonical name (gemma4 is fresh as of 2026-04-08; check `ollama search gemma4` if needed). **Document the exact tag chosen** — it goes verbatim into `settings.model.default`.

2. **Register `@hermes:pytt.io` on conduit (sugar).**
   - Conduit registration is token-gated. SSH to sugar and use the conduit admin room to issue a registration token, OR temporarily flip `services.matrix-conduit.settings.global.allow_registration` to `true`, register via Element, then flip it back.
   - Pick a strong password — it goes into the sops secret, never anywhere else.
   - Verify by logging into Element as `@hermes:pytt.io`.

3. **Create the dedicated hermes Matrix room.**
   - In Element (as your normal user), create a private room `#hermes` (or whatever name).
   - Invite `@hermes:pytt.io` and accept on its behalf.
   - Copy the **internal room ID** (looks like `!XXXX:pytt.io`) — Element → Room Settings → Advanced. This goes into `MATRIX_FREE_RESPONSE_ROOMS` and `MATRIX_HOME_ROOM`.

4. **Grab station's ollama TLS cert.**
   ```sh
   # On nero (or anywhere with reach to station):
   echo | openssl s_client -connect 10.10.10.10:11434 -servername 10.10.10.10 2>/dev/null \
     | openssl x509 -outform PEM > /tmp/station-ollama.pem
   ```
   Inspect with `openssl x509 -in /tmp/station-ollama.pem -text -noout` — confirm the SAN includes `IP:10.10.10.10`. Save this PEM into the nixflake repo as `~/nixflake/hosts/nero/station-ollama.pem` (it's a public cert, safe to commit) so it can be referenced by `security.pki.certificateFiles`.

### Phase 1: Flake input

5. **Add hermes-agent input to `~/nixflake/flake.nix`.** Insert into `inputs = { … };` block, following `brain`'s style:
   ```nix
   hermes-agent = {
     url = "github:NousResearch/hermes-agent";
     inputs.nixpkgs.follows = "nixpkgs-unstable";
   };
   ```
   Run `nix flake lock --update-input hermes-agent` (or just `nix flake update hermes-agent`) to populate `flake.lock`. Verify with `nix flake metadata | grep hermes`.

### Phase 2: Secret

6. **Add `hermes-env` to `~/nixflake/secrets/nero.yaml`.**
   ```sh
   sops ~/nixflake/secrets/nero.yaml
   ```
   Add a key (multiline YAML literal):
   ```yaml
   hermes-env: |
     # Ollama (station, self-signed TLS — cert trusted system-wide via security.pki)
     OPENAI_API_KEY=ollama-dummy

     # Matrix (conduit on sugar)
     MATRIX_HOMESERVER=http://10.10.30.111:6167
     MATRIX_USER_ID=@hermes:pytt.io
     MATRIX_PASSWORD=<the password from Phase 0 step 2>

     # Lock down: only respond in the dedicated room, only to allowed users
     MATRIX_FREE_RESPONSE_ROOMS=!XXXXXX:pytt.io
     MATRIX_HOME_ROOM=!XXXXXX:pytt.io
     MATRIX_REQUIRE_MENTION=true
     MATRIX_ALLOWED_USERS=@odin:pytt.io
   ```
   Note: `MATRIX_HOMESERVER` is plain `http://` because the second-brain bot already talks to conduit that way (see `Brain/nix/modules/second-brain/default.nix:75–79`). Conduit binds 0.0.0.0 on the homelab LAN; no TLS in front of it.

### Phase 3: Nero host config

7. **Edit `~/nixflake/hosts/nero/default.nix`** — three changes:

   a. Add `inputs` to the function args:
   ```nix
   { pkgs, inputs, ... }:
   ```

   b. Add an `imports` entry for the hermes module (alongside the existing `./hardware-configuration.nix`):
   ```nix
   imports = [
     ./hardware-configuration.nix
     inputs.hermes-agent.nixosModules.default
   ];
   ```

   c. Trust station's ollama cert and declare the secret + service. Insert below the existing `server.second-brain` block:
   ```nix
   # Trust station's self-signed ollama cert so hermes' OpenAI client can hit https://10.10.10.10:11434
   security.pki.certificateFiles = [ ./station-ollama.pem ];

   sops.secrets."hermes-env" = {
     owner = "hermes";
     mode = "0400";
   };

   services.hermes-agent = {
     enable = true;
     addToSystemPackages = true;
     environmentFiles = [ config.sops.secrets."hermes-env".path ];
     settings = {
       model = {
         base_url = "https://10.10.10.10:11434/v1";
         default = "gemma4:27b";   # adjust to whatever Phase 0 step 1 produced
       };
       matrix = {
         require_mention = true;
         auto_thread = true;
         free_response_rooms = [ "!XXXXXX:pytt.io" ];   # same room ID as the env var
       };
     };
     documents."SOUL.md" = ''
       # Hermes
       You are Hermes — an experimental general-purpose assistant running on Mr.No's homelab.
       You are NOT the second-brain bot (@brain:pytt.io); you have no vault, no integrations, no proactive systems.
       You are powered by a local Gemma 4 27B model on the homelab GPU. Be concise, technical, and curious.
       Timezone: GMT+1 (Europe/Berlin).
     '';
   };
   ```
   Note: `config` needs to be in the function args too — it already is via `{ pkgs, ... }` plus the implicit module-system args, but make sure the final signature is `{ pkgs, config, inputs, ... }:`.

### Phase 4: Deploy & validate

8. **Deploy.**
   ```sh
   cd ~/nixflake
   just deploy nero
   ```
   Watch for eval errors (option name typos, missing input) and activation errors (sops decryption, user creation).

9. **Verify on nero.** (See Validation Commands section below.)

10. **Smoke test from Element.** Open the dedicated `#hermes` room as `@odin:pytt.io`, send `@hermes ping`, expect a reply within ~10 s (first inference will be slower while gemma4 loads into VRAM on station).

---

## STEP-BY-STEP TASKS

### UPDATE `~/nixflake/flake.nix`
- **IMPLEMENT**: Add `hermes-agent` to the `inputs` attrset.
- **PATTERN**: Mirror `brain` input at `flake.nix:29–32`.
- **IMPORTS**: n/a (flake-level).
- **GOTCHA**: Use `inputs.nixpkgs.follows = "nixpkgs-unstable"`, not `nixpkgs`. Hermes is fast-moving and 25.05 may lag.
- **VALIDATE**: `cd ~/nixflake && nix flake metadata 2>&1 | grep hermes-agent`

### UPDATE `~/nixflake/flake.lock`
- **IMPLEMENT**: Lock the new input.
- **PATTERN**: standard.
- **IMPORTS**: n/a.
- **GOTCHA**: None.
- **VALIDATE**: `cd ~/nixflake && nix flake update hermes-agent && grep -q hermes-agent flake.lock && echo OK`

### CREATE `~/nixflake/hosts/nero/station-ollama.pem`
- **IMPLEMENT**: Save the PEM extracted in Phase 0 step 4.
- **PATTERN**: Plain file. Public cert — safe to commit.
- **IMPORTS**: n/a.
- **GOTCHA**: Make sure it's the *server* cert, not a CA chain that ends up empty. `openssl x509 -in <file> -noout -subject` should print `subject=CN = ollama`.
- **VALIDATE**: `openssl x509 -in ~/nixflake/hosts/nero/station-ollama.pem -noout -ext subjectAltName | grep -q '10.10.10.10' && echo OK`

### UPDATE `~/nixflake/secrets/nero.yaml`
- **IMPLEMENT**: Add `hermes-env` multiline literal with all `MATRIX_*`, `OPENAI_API_KEY` vars.
- **PATTERN**: Existing `second_brain_*` secrets in the same file.
- **IMPORTS**: n/a.
- **GOTCHA**: `MATRIX_FREE_RESPONSE_ROOMS` is comma-separated, not YAML list — it's a flat env var. Do NOT use bracket syntax. Conduit URL is `http://`, not `https://`.
- **VALIDATE**: `sops -d ~/nixflake/secrets/nero.yaml | grep -A1 'hermes-env:' | head` (locally, before deploy).

### UPDATE `~/nixflake/hosts/nero/default.nix`
- **IMPLEMENT**: Add `inputs` and `config` to function args, add hermes module to `imports`, add `security.pki.certificateFiles`, `sops.secrets."hermes-env"`, and `services.hermes-agent` block.
- **PATTERN**: Existing `server.second-brain = { … };` block lines 29–39.
- **IMPORTS**: `inputs.hermes-agent.nixosModules.default`.
- **GOTCHA**: Don't forget `config` in the function args — needed for `config.sops.secrets."hermes-env".path`. Don't try to namespace under `server.hermes` — we're using upstream's `services.hermes-agent` directly (decision: inline, not wrapped).
- **VALIDATE**: `cd ~/nixflake && nix eval .#nixosConfigurations.nero.config.services.hermes-agent.enable` should return `true`.

### DEPLOY to nero
- **IMPLEMENT**: `cd ~/nixflake && just deploy nero`
- **PATTERN**: Standard deploy flow.
- **GOTCHA**: First deploy will pull hermes-agent + all its python deps; expect ~minutes. Watch the deploy output for `hermes` user creation and the activation script.
- **VALIDATE**: see Validation Commands below.

---

## TESTING STRATEGY

This is infrastructure — there is no unit test suite. "Testing" = post-deploy validation commands plus manual smoke test.

### Edge Cases to Verify
- **Self-signed cert trust** — if `OPENAI_API_KEY` calls fail with `SSL: CERTIFICATE_VERIFY_FAILED`, the PEM didn't land in the system trust store. Re-check that the file is referenced by `security.pki.certificateFiles` and that `nixos-rebuild switch` rebuilt the CA bundle (`update-ca-trust` or equivalent).
- **Model not pulled on station** — first inference call will return an ollama error. Phase 0 step 1 must have completed. Check `curl -k https://10.10.10.10:11434/api/tags | jq .` from nero.
- **Wrong room ID** — hermes will silently ignore messages. Compare `MATRIX_FREE_RESPONSE_ROOMS` against the room internal ID (must start with `!`, not `#`).
- **Conduit registration didn't take** — login on hermes' side will fail; check `journalctl -u hermes-agent` for `M_FORBIDDEN`.
- **Two bots in same room** — if you accidentally invite `@brain` to `#hermes` (or vice versa), they'll both reply to mentions. Keep them in separate rooms.
- **GPU contention** — if station is also running other ollama loads, gemma4:27b may OOM. Confirm `nvidia-smi` headroom on station before first call.

---

## VALIDATION COMMANDS

Run all of these after `just deploy nero` succeeds. Each must return zero/expected output.

### Level 1: Eval & build
```sh
cd ~/nixflake
nix flake check 2>&1 | tail -20                                     # no eval errors
nix eval .#nixosConfigurations.nero.config.services.hermes-agent.enable    # -> true
nix eval .#nixosConfigurations.nero.config.services.hermes-agent.settings.model.default  # -> "gemma4:27b"
```

### Level 2: Service health on nero
```sh
ssh odin@nero 'systemctl status hermes-agent --no-pager'            # active (running)
ssh odin@nero 'journalctl -u hermes-agent --since "5 min ago" --no-pager | tail -50'   # no tracebacks, no SSL errors, no M_FORBIDDEN
ssh odin@nero 'systemctl status second-brain-bot --no-pager'        # still active — coexistence check
```

### Level 3: Backend reachability from nero
```sh
ssh odin@nero 'curl -sf https://10.10.10.10:11434/api/tags | jq -r ".models[].name"'   # lists models, includes gemma4:27b
ssh odin@nero 'curl -sf https://10.10.10.10:11434/v1/models | jq .'                    # OpenAI-compat surface works
# Trust check (no -k):
ssh odin@nero 'curl -sf https://10.10.10.10:11434/api/version'                          # succeeds WITHOUT --insecure -> cert is trusted
```

### Level 4: CLI sharing & config
```sh
ssh odin@nero 'hermes version'                                       # CLI on PATH
ssh odin@nero 'hermes config'                                        # shows Nix-generated config.yaml, model.base_url is the ollama URL
ssh odin@nero 'sudo ls -la /var/lib/hermes/.hermes/'                 # state dir present, owned by hermes
```

### Level 5: End-to-end manual test
1. Open Element as `@odin:pytt.io`.
2. Go to the dedicated `#hermes` room.
3. Send: `@hermes hello, what model are you running?`
4. Expect a reply within ~15s naming Gemma (or describing local inference).
5. Send the same prompt in the second-brain bot's room — confirm `@brain` (NOT `@hermes`) replies. Cross-contamination = misconfigured `MATRIX_FREE_RESPONSE_ROOMS`.

---

## ACCEPTANCE CRITERIA

- [ ] `hermes-agent` flake input present in `flake.nix` and locked in `flake.lock`, following `nixpkgs-unstable`.
- [ ] `services.hermes-agent.enable = true` evaluates on `nero`.
- [ ] `systemctl status hermes-agent` on nero is `active (running)` after `just deploy nero`.
- [ ] `hermes` CLI is on PATH on nero (`addToSystemPackages = true` worked).
- [ ] `curl https://10.10.10.10:11434/api/tags` on nero succeeds **without** `-k` (cert trust works).
- [ ] gemma4:27b is listed on station and selected by hermes.
- [ ] `@hermes:pytt.io` replies in the dedicated room when mentioned.
- [ ] `@hermes` does NOT reply outside the configured `MATRIX_FREE_RESPONSE_ROOMS`.
- [ ] `second-brain-bot.service` is still running and replies normally — no regression.
- [ ] No API key for any cloud provider exists on nero (this is fully local inference).

---

## COMPLETION CHECKLIST

- [ ] Phase 0 prerequisites complete (model pulled, Matrix user registered, room created, cert grabbed).
- [ ] Flake input added + locked.
- [ ] Sops secret added with all `MATRIX_*` env vars and dummy `OPENAI_API_KEY`.
- [ ] PEM committed under `hosts/nero/`.
- [ ] `hosts/nero/default.nix` updated with import + service block + cert trust.
- [ ] `just deploy nero` succeeds.
- [ ] All Validation Commands pass.
- [ ] Smoke test in Element succeeds.
- [ ] Both bots coexist; no cross-room replies.

---

## NOTES

### Decisions locked in
- **Native, not container** — matches second-brain hardening style; no docker on nero today.
- **Inline in `hosts/nero/default.nix`, not wrapped under `server.hermes.*`** — only one host will run hermes for the foreseeable future; wrap later if a second host appears.
- **Self-signed cert trusted via `security.pki`, not `--insecure` flags** — keeps hermes' default HTTPS client happy without forking config. The PEM is public; safe to commit.
- **Password login, not access token** — simpler bootstrap; switch to `MATRIX_ACCESS_TOKEN` later if password rotation gets annoying.
- **`OPENAI_API_KEY=ollama-dummy`** — ollama's OpenAI-compat endpoint ignores the value but the OpenAI client refuses to start without one set.
- **Locked to a single room via `MATRIX_FREE_RESPONSE_ROOMS` + `MATRIX_REQUIRE_MENTION=true`** — minimizes blast radius while experimenting.

### Risks
- **Hermes is fast-moving.** Option names in the upstream module may have drifted by the time of implementation. **Verify** by reading `inputs.hermes-agent.nixosModules.default` source after `nix flake update`, OR by running `nix eval .#nixosConfigurations.nero.options.services.hermes-agent --apply 'opts: builtins.attrNames opts'` to dump current option names.
- **Gemma 4 tag** — if `gemma4:27b` isn't the canonical name, the service will start but the first inference call will 404. Adjust based on `ollama list` output on station.
- **Conduit federation / login quirks** — if the bot's first login attempts get rate-limited or rejected, it may need a registration token instead of password. Watch journalctl on first start.
- **GPU memory pressure on station** — if other workloads are using the 3090, gemma4:27b at q4 (~17 GB) may not fit. Monitor `nvidia-smi` on station after the first inference.

### Out of scope
- Wiring hermes to MCP servers (filesystem, github, etc.) — defer until base deployment is stable.
- Sharing state with the second-brain vault — hermes lives in its own `/var/lib/hermes` and does NOT touch `Brain-Vault`.
- Heartbeat / reflection / memory — none of the proactive systems from second-brain apply here.
- Migrating second-brain bot to local inference — separate decision, not coupled to this plan.
