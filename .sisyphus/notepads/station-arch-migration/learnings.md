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
