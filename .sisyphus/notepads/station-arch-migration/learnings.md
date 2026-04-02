# Learnings — station-arch-migration

## [2026-04-02] Initial Analysis

### Flake Structure
- `flake.nix` imports: `parts/hosts.nix`, `parts/dev.nix`, `parts/deploy.nix`
- Need to ADD: `./parts/home-manager-standalone.nix` to flake.nix imports
- All inputs already in flake: nixpkgs (25.05), home-manager (25.05), stylix (release-25.05), sops-nix, nixvim, zen-browser, colmena
- No nixpkgs-unstable input needed for standalone HM (desktop uses stable 25.05)

### HM Module Pattern (CRITICAL)
- All `modules/home-manager/` files are **NixOS modules**, NOT standalone HM modules
- They define NixOS options (e.g., `options.git.enable`) AND write HM config via `config.home-manager.users.${config.user}`
- `config.user` comes from `modules/home-manager/default.nix` which defines `options.user`
- Example pattern (git.nix):
  ```nix
  options.git.enable = lib.mkEnableOption "...";
  config.home-manager.users.${config.user} = lib.mkIf config.git.enable { ... };
  ```

### lib.nix Module Chain
- `commonModules` = `../modules` (ALL nixos + home-manager modules) + stylix.nixosModules + home-manager.nixosModules + sops-nix.nixosModules
- `../modules` means `modules/default.nix` which imports everything (nixos + home-manager)
- For standalone: we need to import home-manager modules WITHOUT the NixOS context

### styling.nix Key Details
- Defines options: `styling.{enable,theme,wallpaper,polarity,opacity.terminal,cursor.{package,name,size},autoEnable}`
- Default wallpaper: `../../modules/home-manager/desktop/hyprland/wallpaper/wallpaper.png`
- Default opacity: 0.85 (already correct for station)
- Sets `stylix.*` NixOS options (so standalone needs `homeModules.stylix` instead)

### secrets.nix Key Details
- Default sopsFile: `secrets/secrets.yaml` (NOT `general.yaml` — `general.yaml` in station/default.nix is stale)
- Decrypts: ssh keys, `github_token` (mode 0400)
- age keyFile: `/home/${config.user}/.config/sops/age/keys.txt`

### NixOS Configs in flake (9 total)
- Desktops: laptop, VNPC-21, station
- Servers: pulse, sugar, byob, psychosocial, spiders
- Special: installer

### Important: nixvim integration
- In `parts/lib.nix:hostModules`, nixvim is added via `imports = [ nixvim.homeModules.nixvim ]` inside `home-manager.users.${user}`
- Standalone will need to add `nixvim.homeModules.nixvim` to imports in `home-manager-standalone.nix`

## [2026-04-02T00:00:00Z] Task: T2
- Added new flake-parts module `parts/home-manager-standalone.nix` with `flake.homeConfigurations."none@station"` via `inputs.home-manager.lib.homeManagerConfiguration`.
- Standalone HM uses stable `inputs.nixpkgs` with `allowUnfree = true` and passes `extraSpecialArgs = { inputs; pkgs-unstable; }` where `pkgs-unstable` mirrors `parts/lib.nix` (`localSystem = "x86_64-linux"`).
- Standalone modules are intentionally minimal: `inputs.nixvim.homeModules.nixvim` + `hosts/station-arch/home.nix` only (no `modules/nixos` or `modules/server`, no shared HM module tree yet).
- `nix eval .#homeConfigurations."none@station".activationPackage.drvPath` and all requested nixosConfiguration drvPath evals succeed.
- Note: `nix flake show --json | jq '.homeConfigurations'` renders `{ "type": "unknown" }` on this Nix version for non-standard outputs; direct eval confirms `none@station` exists.

## [2026-04-02] Task 5 — sops-nix standalone HM validation
- `inputs.sops-nix.homeManagerModules.sops` evaluates successfully in standalone HM (`none@station`) when added to `parts/home-manager-standalone.nix` and `sops` basics are set in `hosts/station-arch/home.nix`.
- Eval proof: `.sisyphus/evidence/task-5-sops-standalone.txt` contains a successful activation derivation path.
- Standalone HM path behavior (from evaluated options + upstream module source):
  - `sops.defaultSymlinkPath` default resolves to `${config.xdg.configHome}/sops-nix/secrets` (here: `/home/none/.config/sops-nix/secrets`)
  - `sops.defaultSecretsMountPoint` default is `%r/secrets.d` (`%r` = runtime dir on Linux)
  - So HM consumers should not assume `/run/secrets/*`.
- Full grep under `modules/home-manager/**/*.nix` found only one impacted module/path:
  - `modules/home-manager/cli/mcp.nix` uses `/run/secrets/github_token` (2 hits)
- Recommended migration pattern: declare `sops.secrets.github_token = { };` in standalone `home.nix`, then consume `config.sops.secrets.github_token.path` in modules.

## [2026-04-02T00:00:00Z] Task: T4 Stylix standalone HM validation
- Verified standalone Stylix works when importing `inputs.stylix.homeModules.stylix` in `parts/home-manager-standalone.nix` modules list.
- Full tested option set evaluated successfully in standalone HM: `stylix.enable`, `base16Scheme`, `image`, `polarity`, `opacity.terminal`, `autoEnable`, and `cursor.{package,name,size}`.
- Eval command: `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1` → returned a valid home-manager generation drv path.
- `modules/nixos/styling.nix` remains a NixOS wrapper (`styling.*` namespace + `home-manager.users.${config.user}` wiring); for standalone HM, configure `stylix.*` directly in HM config/module.
- Temporary test changes were reverted: `hosts/station-arch/home.nix` back to minimal skeleton and `parts/home-manager-standalone.nix` back to no Stylix module.

## [2026-04-02] Task 6 — standalone HM compatibility layer
- A pure shim that both defines `home-manager.users` and merges `lib.attrValues config.home-manager.users` back into top-level standalone HM config still hit infinite recursion in this module graph, even after trying `submoduleWith { freeformType = lib.types.anything; }` for mergeable user entries.
- The stable fallback was to keep `modules/home-manager/standalone-compat.nix` focused on providing the shared option surface (`user`, `hyprland.*`, `home-manager.users`) and add a pilot standalone branch directly in `modules/home-manager/cli/git.nix`.
- The git pilot uses `options ? nixpkgs` to distinguish NixOS mode from standalone HM mode: NixOS still writes only to `home-manager.users.${config.user}`, while standalone HM additionally emits the same HM config at top level.
- Verification results:
  - standalone HM eval with shim + git pilot succeeded: `/nix/store/npv6nzcis6qg4lgvr2allw3knjkvw7ph-home-manager-generation.drv`
  - station NixOS drvPath remained identical before/after: `/nix/store/gzimfjqgby17ap6cjrdpjiwi3w2slw7l-nixos-system-station-25.05.20260102.ac62194.drv`

## [2026-04-02] Task 7 — pilot dual-mode expansion (hyprland + mcp)
- Applied the same dual-mode pattern from `git.nix` to `modules/home-manager/desktop/hyprland/default.nix` and `modules/home-manager/cli/mcp.nix` using `standalone = !(options ? nixpkgs)` and `lib.mkMerge` with a direct standalone HM branch.
- `hyprland/default.nix` now preserves NixOS behavior while standalone HM overrides only `wayland.windowManager.hyprland.package = null` so Arch/pacman Hyprland is used.
- `mcp.nix` now splits config into `hmConfigNixOS` (keeps `/run/secrets/github_token`) and `hmConfigStandalone` (uses `config.sops.secrets.github_token.path` when available, otherwise `/run/user/1000/secrets/github_token`). MCP server definitions were left unchanged.
- Standalone module list now imports all three pilot modules (`git.nix`, `hyprland/default.nix`, `mcp.nix`), and `hosts/station-arch/home.nix` enables `mcp.enable = true`.
- Verified station NixOS drvPath stayed identical through pilot checks (`/nix/store/gzimfjqgby17ap6cjrdpjiwi3w2slw7l-nixos-system-station-25.05.20260102.ac62194.drv`) and standalone HM eval succeeded (`/nix/store/npv6nzcis6qg4lgvr2allw3knjkvw7ph-home-manager-generation.drv`).

## [2026-04-02] Task 10 — neovim/default.nix dual-mode migration
- Applied dual-mode pattern to `modules/home-manager/cli/neovim/default.nix`: added `options` arg, `standalone = !(options ? nixpkgs)` detection, extracted `hmConfig` with imports + home settings, `lib.mkMerge` with standalone branch.
- All neovim submodules (`nixvim.nix`, `lsp.nix`, `harpoon.nix`, etc.) confirmed pure HM modules — they set `programs.nixvim.*` or similar HM attrs directly with no NixOS wrapping. Left UNCHANGED.
- `hmConfig` contains `imports = [ ./nixvim.nix ./lsp.nix ... ]` — relative paths in the attrset work correctly in both NixOS (nested under `home-manager.users.${user}`) and standalone HM (merged at top level) because Nix resolves them relative to `default.nix` at parse time.
- `parts/home-manager-standalone.nix`: added `../modules/home-manager/cli/neovim/default.nix` to modules list.
- `hosts/station-arch/home.nix`: added `neovim.enable = true`.
- Station NixOS drvPath unchanged: `/nix/store/gzimfjqgby17ap6cjrdpjiwi3w2slw7l-nixos-system-station-25.05.20260102.ac62194.drv` ✓
- Standalone HM eval succeeded: `/nix/store/npv6nzcis6qg4lgvr2allw3knjkvw7ph-home-manager-generation.drv` ✓

## [2026-04-02] Task 12 — Remaining hyprland modules dual-mode refactor
- Applied the dual-mode pattern (`standalone = !(options ? nixpkgs)`) to all 5 remaining hyprland modules: `packages.nix`, `services.nix`, `hyprpanel.nix`, `keybindings.nix`, `monitors.nix`.
- All modules follow the same `let standalone = ...; hmConfig = {...}; in { config = lib.mkMerge ([NixOS] ++ lib.optionals standalone [standalone]) }` structure.
- `services.nix` references `config.hyprland.kanshi.profiles` inside `hmConfig` — lazy Nix evaluation means this is safe; `standalone-compat.nix` provides the option with default `[]` which triggers the fallback kanshi config (correct).
- `monitors.nix` references `config.hyprland.monitors.extraConfig` inside `hmConfig` — same pattern; default `""` triggers the fallback workspace config (correct).
- All 5 modules added to `parts/home-manager-standalone.nix` modules list after `hyprland/default.nix`.
- station NixOS drvPath UNCHANGED: `/nix/store/gzimfjqgby17ap6cjrdpjiwi3w2slw7l-nixos-system-station-25.05.20260102.ac62194.drv` ✓
- standalone HM eval SUCCESS: `/nix/store/npv6nzcis6qg4lgvr2allw3knjkvw7ph-home-manager-generation.drv` ✓

## [2026-04-02] Task 11 — dual-mode app modules
- Applied `standalone = !(options ? nixpkgs)` + `lib.mkMerge` dual-mode pattern to all 6 app modules: `discord.nix`, `development.nix`, `media.nix`, `communication.nix`, `utilities.nix`, `lmstudio.nix`.
- `app/default.nix` needed NO changes — it only imports the individual files, no options defined.
- All app modules added to `parts/home-manager-standalone.nix` modules list (after `mcp.nix`, before `hosts/station-arch/home.nix`).
- `hosts/station-arch/home.nix` updated with: `discord.enable`, `development.enable`, `media.enable`, `communication.enable`, `utilities.enable`, `lmstudio.enable` all set to `true`.
- `utilities.nix` uses `inputs` for `claude-code` and `pkgs-unstable` for opencode — both available via `extraSpecialArgs` in standalone.
- `development.nix` and `media.nix` use `pkgs-unstable` — also available.
- station NixOS drvPath UNCHANGED: `/nix/store/gzimfjqgby17ap6cjrdpjiwi3w2slw7l-nixos-system-station-25.05.20260102.ac62194.drv` ✓
- standalone HM eval SUCCESS: `/nix/store/npv6nzcis6qg4lgvr2allw3knjkvw7ph-home-manager-generation.drv` ✓

## [2026-04-02] Task 9 — CLI modules dual-mode refactor

- Applied `standalone = !(options ? nixpkgs)` + `lib.mkMerge` dual-mode pattern to 11 CLI modules:
  `zsh/default.nix`, `tmux.nix`, `kitty.nix`, `ghostty.nix`, `zellij.nix`, `direnv.nix`,
  `kubernetes.nix`, `languages.nix`, `system-tools.nix`, `xdg.nix`, `prompt.nix`.
- Skipped 3 pure HM sub-modules (no `config.home-manager.users` pattern):
  - `zsh/zsh.nix` — pure HM module, sets `programs.zsh.*` directly
  - `zsh/aliases.nix` — plain Nix attrset, not a NixOS module
  - `zsh/eza.nix` — pure HM module, sets `programs.eza.*` directly
- `zsh/default.nix` had submodule imports inside `home-manager.users.*`. Solution: NixOS path
  kept unchanged (still uses `imports = [./zsh.nix ./eza.nix]`); standalone path uses an
  inlined `hmConfig` with equivalent content from `zsh.nix` + `eza.nix` merged.
- `xdg.nix` had `options.xdg.enable` conflicting with HM's own `xdg.enable` in standalone.
  Fix: moved the option declaration to `modules/home-manager/default.nix` (NixOS-only chain).
  In standalone, HM's own `xdg.enable` is used as gate — no re-declaration needed.
  NixOS drvPath unchanged because option is still declared, just in the parent file.
- `parts/home-manager-standalone.nix` was already updated (from a previous task) to import
  `cli/default.nix` which pulls in all CLI modules.
- `hosts/station-arch/home.nix` updated with all CLI enables:
  `zsh.enable`, `prompt.enable`, `kitty.enable`, `ghostty.enable`, `tmux.enable`,
  `system-tools.enable`, `direnv.enable`, `languages.enable`, `kubernetes.enable`,
  `xdg.enable`, `zellij.enable` all set to `true`.
- station NixOS drvPath UNCHANGED: `/nix/store/gzimfjqgby17ap6cjrdpjiwi3w2slw7l-nixos-system-station-25.05.20260102.ac62194.drv` ✓
- standalone HM eval SUCCESS: `/nix/store/gyjz2jf2fgl7bhxiswzr4s175hq3rbkc-home-manager-generation.drv` ✓
