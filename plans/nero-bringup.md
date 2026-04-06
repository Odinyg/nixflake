# Plan: Bring up `nero` host + prepare for second-brain migration

Companion plan to `Brain/.agent/plans/unify-brain-and-nix-module.md`. This plan covers the nixflake side: adding `nero` as a new homelab server, switching its IP from the current `10.10.30.47` to the target `10.10.30.115`, and provisioning the sops secrets needed by the second-brain module. The actual migration of second-brain off sugar onto nero happens in the Brain plan after this is complete.

## Context

- **nero**: existing NixOS VM, currently on `10.10.30.47`, target IP `10.10.30.115`
- **Purpose**: dedicated host for second-brain (Matrix bot, heartbeat, reflection, vault sync). Nothing else moves to nero — sugar keeps its other services (Caddy, vaultwarden, freshrss, conduit/Matrix, etc.)
- **Conduit stays on sugar**: nero's bot connects to `http://10.10.30.111:6167` over the LAN. Conduit already binds `0.0.0.0` (`modules/server/matrix.nix:45`), and homelab servers have no firewall (per `CLAUDE.md`), so no extra plumbing needed.
- **Cutover style**: hard cutover. Sugar's `server.second-brain.enable = true` flips to `false` only after nero is fully running and verified. No parallel operation.
- **Sops scope**: nero needs its own age key + a new `secrets/nero.yaml` file containing every secret the second-brain module references, plus the new `second_brain_deploy_key` from the refactor.

## Phases

### Phase A: Add nero to nixflake (current IP)
Get nero buildable + deployable on its existing `10.10.30.47` first. Don't touch the IP yet.

### Phase B: Provision sops secrets for nero
Generate age key from nero's host SSH key, register in `.sops.yaml`, create `secrets/nero.yaml` with all second-brain secrets copied from `secrets/sugar.yaml` plus the new deploy key.

### Phase C: Switch nero to target IP `10.10.30.115`
Add `networking.interfaces.<iface>.ipv4.addresses` (or whatever pattern nixflake uses for static IPs — verify against another homelab host) to `hosts/nero/default.nix`. Deploy. Verify reachable on new IP. Update `parts/deploy.nix` `targetHost` to the new IP.

### Phase D: Hand off to Brain plan
At this point nero is in nixflake, reachable, has sops working, but **does not have second-brain enabled yet**. The Brain plan picks up here: enable `server.second-brain` on nero with its new options (matrix.homeserver pointing at sugar), verify bootstrap clones both repos, verify bot/heartbeat/reflection/vault-sync all green, then disable on sugar in a follow-up commit.

---

## Tasks

### 1. INSPECT — verify nero is reachable on current IP

- `ssh odin@10.10.30.47 'hostname; uname -a; nixos-version'`
- Confirm: it answers, hostname shows something we can override to `nero`, NixOS version is recent

### 2. INSPECT — find a reference host for static IP pattern

- Read `hosts/sugar/default.nix`, `hosts/pulse/default.nix`, `hosts/byob/default.nix` — find which one uses a static IP and copy that pattern. If they all rely on DHCP + LAN reservations, that's fine too — note which approach this fleet uses.

### 3. CREATE `hosts/nero/default.nix` (minimal)

- Mirror the structure of `hosts/sugar/default.nix` but stripped to bare essentials:
  - `networking.hostName = "nero";`
  - SSH enabled, odin user, authorized keys
  - sops setup (will be wired in task 7)
  - **No services enabled yet** — second-brain comes later via the Brain plan
- Reference `mkServer` pattern from `parts/hosts.nix` — uses `nixpkgs-unstable`, no home-manager, no stylix

### 4. CREATE `hosts/nero/hardware-configuration.nix`

- `ssh odin@10.10.30.47 'sudo nixos-generate-config --show-hardware-config'` and save the output to `hosts/nero/hardware-configuration.nix`
- VALIDATE: file is non-empty, contains `boot.initrd.availableKernelModules`, `fileSystems."/"`

### 5. ADD nero to `parts/hosts.nix`

- Add under "Homelab servers":
  ```nix
  nero = mkServer {
    hostPath = ../hosts/nero;
  };
  ```
- VALIDATE: `nix flake check` passes

### 6. ADD nero to `parts/deploy.nix`

- Add under "Homelab servers":
  ```nix
  nero = mkColmenaServer {
    hostPath = ../hosts/nero;
    targetHost = "10.10.30.47";   # current IP, will change in task 14
  };
  ```
- Add `"nero"` to the `serverHosts` list (line 53–59) so it gets unstable nixpkgs
- VALIDATE: `nix flake check` passes; `nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath` returns a path

### 7. GENERATE nero's age key from its SSH host key

```bash
ssh odin@10.10.30.47 'sudo cat /etc/ssh/ssh_host_ed25519_key.pub' | nix-shell -p ssh-to-age --run ssh-to-age
```
Output is the `age1...` key. Save it.
- VALIDATE: starts with `age1`, ~62 chars

### 8. UPDATE `.sops.yaml`

- Add an anchor under "Homelab servers":
  ```yaml
  - &nero <age1... from task 7>
  ```
- Add a creation rule:
  ```yaml
  - path_regex: secrets/nero\.yaml$
    key_groups:
      - age:
          - *nero
  ```
- Decide tier: nero hosts the AI agent + creds for many integrations — treat as `homelab_critical` OR `homelab_general`. Look at where `sugar` sits (`homelab_general`) and match. For symmetry with sugar, also add `homelab_general` to the nero rule so the same admin keys can decrypt.
- VALIDATE: `sops -d secrets/nero.yaml` (will fail because file doesn't exist yet — that's fine, we just want syntax check on .sops.yaml)

### 9. CREATE `secrets/nero.yaml`

Copy from `secrets/sugar.yaml` everything under the `second_brain_*` keys:
```bash
sops -d secrets/sugar.yaml > /tmp/sugar-decrypted.yaml
# manually extract second_brain_* keys into a new file
sops -e /tmp/nero-plain.yaml > secrets/nero.yaml
shred -u /tmp/sugar-decrypted.yaml /tmp/nero-plain.yaml
```
Or simpler: `sops` supports per-file editing, just create the new file with `sops secrets/nero.yaml` and paste each value.

Required keys (from current `modules/server/second-brain.nix:138-148`):
- `second_brain_matrix_token`
- `second_brain_todoist_token`
- `second_brain_github_token`
- `second_brain_mealie_url`
- `second_brain_mealie_token`
- `second_brain_wger_url`
- `second_brain_wger_token`
- `second_brain_homeassistant_url`
- `second_brain_homeassistant_token`

**NEW from the Brain refactor:**
- `second_brain_deploy_key` — the ed25519 private key generated in the Brain plan task 10. **Same key as sugar's** — both hosts use the same forgejo deploy key.

VALIDATE: `sops -d secrets/nero.yaml | grep -c second_brain_` returns 10

### 10. WIRE sops into `hosts/nero/default.nix`

- Add:
  ```nix
  sops.defaultSopsFile = ../../secrets/nero.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  ```
- (Or whatever pattern sugar uses — read `hosts/sugar/default.nix` for the exact lines and copy.)
- VALIDATE: `nix flake check` passes

### 11. INITIAL DEPLOY to nero (current IP)

- `git add -A && git commit -m "feat(nero): add host config (current IP)"`
- `cd /home/none/nixflake && just deploy nero`
- Watch for activation errors. If sops fails to decrypt, the age key in `.sops.yaml` is wrong — go back to task 7.
- VALIDATE:
  - `ssh odin@10.10.30.47 'hostname'` returns `nero`
  - `ssh odin@10.10.30.47 'systemctl status sshd'` is active
  - `ssh odin@10.10.30.47 'sudo ls /run/secrets/'` shows decrypted secret files (proves sops works)

### 12. ADD static IP config to `hosts/nero/default.nix`

- Find the network interface name on nero: `ssh odin@10.10.30.47 'ip -br link'`
- Add:
  ```nix
  networking = {
    hostName = "nero";
    useDHCP = false;
    interfaces.<iface>.ipv4.addresses = [{
      address = "10.10.30.115";
      prefixLength = 24;
    }];
    defaultGateway = "10.10.30.1";   # confirm with `ip route` on nero
    nameservers = [ "10.10.30.1" ];   # or whatever the LAN DNS is
  };
  ```
- **GOTCHA**: pattern may differ if nixflake uses systemd-networkd or NetworkManager elsewhere. Check sugar/pulse for the project's idiom and match it.
- VALIDATE: `nix flake check` passes; `nix eval .#nixosConfigurations.nero.config.networking.interfaces` shows the new address

### 13. DEPLOY the IP change

- `git commit -m "feat(nero): switch to target IP 10.10.30.115"`
- `just deploy nero` — **the deploy will be executed against the OLD IP `10.10.30.47`**, the activation will switch the IP, the SSH session will drop. This is expected.
- VALIDATE:
  - `ping 10.10.30.115` succeeds within 30s
  - `ssh odin@10.10.30.115 'hostname'` returns `nero`
  - `ssh odin@10.10.30.47` fails (old IP gone)
- **GOTCHA**: If the deploy hangs because it can't reach the new IP yet, that's normal — colmena will time out. The deploy actually succeeded if nero is reachable on the new IP.

### 14. UPDATE `parts/deploy.nix` targetHost

- Change nero's `targetHost = "10.10.30.47"` to `targetHost = "10.10.30.115"`
- Commit: "chore(nero): update colmena targetHost to production IP"
- VALIDATE: `just deploy nero` is a no-op (or only restarts services if anything else changed)

### 15. ADD nero to ~/.ssh/config (workstation, optional but ergonomic)

```
Host nero
    HostName 10.10.30.115
    User odin
```
This is local-only, not committed. After this you can `ssh nero` per the existing `feedback_ssh_sugar.md` memory pattern.

---

## Hand-off to the Brain plan

After task 14, nero is in nixflake, reachable on 10.10.30.115, sops working with all second-brain secrets pre-provisioned (including the deploy key). The Brain refactor plan picks up here at its Phase 5 with the following changes:

### Modifications to Brain plan tasks when targeting nero

- **Brain plan task 10 (generate deploy key)**: still happens, key still goes into BOTH `secrets/sugar.yaml` (via this plan's task 9 — though sugar is being decommissioned, leaving the key there is harmless) and `secrets/nero.yaml`. Or skip sugar entirely if you're not going to enable second-brain there ever again. Recommended: only put the key in `secrets/nero.yaml` to keep sugar.yaml minimal.

- **Brain plan task 17 (module options)**: when enabling on nero, override `matrix.homeserver`:
  ```nix
  # In hosts/nero/default.nix
  server.second-brain = {
    enable = true;
    projectDir   = "/home/odin/projects/Brain";
    vaultDir     = "/home/odin/projects/Brain-Vault";
    matrix.homeserver = "http://10.10.30.111:6167";   # sugar's conduit
    matrix.userId     = "@brain:pytt.io";
    matrix.notifyRoom = "!ExLmjhT_x3E2dLwnd1Ef3dgaWezPJC0-X6Oqk3Tcy_Q";
  };
  ```
  Compare to sugar's current block in `hosts/sugar/default.nix:92-98` — the only differences are `vaultDir` (new) and `matrix.homeserver` (now points across the LAN instead of localhost).

- **Brain plan task 29 (deploy)**: deploy to **nero**, not sugar. `just deploy nero`. Sugar continues running its existing second-brain setup unchanged until cutover.

- **Brain plan task 31 (end-to-end test)**: must verify nero's bot can reach sugar's conduit. If the Matrix DM works, this proves cross-host conduit reachability.

- **NEW task between Brain plan tasks 31 and 32 (cutover)**: 
  1. SSH sugar, manually trigger one final `second-brain-vault-sync.service` to flush any pending writes (or wait for the next 5-min tick on the OLD `second-brain-sync` which still exists on sugar at this point)
  2. Edit `hosts/sugar/default.nix:92`: change `enable = true` to `enable = false`
  3. Commit: "chore(sugar): disable second-brain (migrated to nero)"
  4. `just deploy sugar` — should stop and disable all `second-brain-*` units on sugar
  5. VERIFY on sugar: `systemctl list-units 'second-brain-*'` shows no active units; `ls /home/odin/projects/Brain` and `Brain-Vault` still exist on disk (preserve as backup; delete manually after a week if you want)

- **Brain plan task 32 (delete `Brain/Memory/`)**: now happens against nero, not sugar. After deletion, manually `ssh nero 'git -C ~/projects/Brain pull'` to bring nero's checkout in sync with the deletion.

---

## Sops secrets summary

| Secret | Purpose | Source |
|---|---|---|
| `second_brain_matrix_token` | Bot login to conduit on sugar | Existing on sugar.yaml — copy |
| `second_brain_todoist_token` | Todoist API | Copy |
| `second_brain_github_token` | GitHub API | Copy |
| `second_brain_mealie_url` | Mealie endpoint | Copy |
| `second_brain_mealie_token` | Mealie API | Copy |
| `second_brain_wger_url` | WGER endpoint | Copy |
| `second_brain_wger_token` | WGER API | Copy |
| `second_brain_homeassistant_url` | HA endpoint | Copy |
| `second_brain_homeassistant_token` | HA API | Copy |
| `second_brain_deploy_key` | forgejo deploy key (write access on Brain + brain-vault) | NEW — generated in Brain plan task 10 |

All 10 keys go into `secrets/nero.yaml`, encrypted with `nero` + `homelab_general` age keys.

## Validation summary

After completing this plan:
- `ssh nero` works on `10.10.30.115`
- `nix eval .#nixosConfigurations.nero.config.system.build.toplevel.drvPath` returns a path
- `sops -d secrets/nero.yaml | grep -c second_brain_` returns 10
- All 10 secrets decrypt cleanly on nero: `ssh nero 'sudo ls /run/secrets/'` shows them
- nero reachable from sugar: `ssh sugar 'curl -s http://10.10.30.115/health || echo unreachable'` (no service yet, but TCP should respond — at least `ping 10.10.30.115` works from sugar)
- nero can reach sugar's conduit: `ssh nero 'curl -s http://10.10.30.111:6167/_matrix/client/versions'` returns JSON
- Sugar's second-brain still running (untouched until Brain plan cutover)

## Risks

- **IP change deploy (task 13)**: SSH session drops mid-deploy. Standard nixflake operation but worth knowing. If activation fails before applying the new IP, nero stays on `10.10.30.47` — recoverable.
- **Sops creation rules (task 8)**: easy to typo. The creation rule's `path_regex` must match the file path exactly. If wrong, encryption uses no keys and the file is unreadable. Test with `sops secrets/nero.yaml` (creation flow) and verify the file has the right recipients in its metadata.
- **Hardware-config drift (task 4)**: if nero is rebuilt or its disk layout changes, the captured `hardware-configuration.nix` won't match. Re-generate if you ever rebuild nero.
- **Cross-host conduit traffic**: not authenticated at the network layer. The Matrix access token IS the auth, and that's already secret. But if you ever set up a DMZ between the LAN and nero, the bot will lose conduit access. Worth knowing.
