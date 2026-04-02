# Decisions — station-arch-migration

## [2026-04-02] Architecture Decisions

### Flake Output
- New `homeConfigurations."none@station"` in `parts/home-manager-standalone.nix`
- Uses `inputs.home-manager.lib.homeManagerConfiguration` (NOT nixpkgs.lib.nixosSystem)
- pkgs = `import inputs.nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }`
- extraSpecialArgs must include `inputs` and `pkgs-unstable`

### HM Module Compatibility (Task 6 to decide)
- Two candidates:
  A) Compatibility shim: provide fake `config.home-manager.users.${user}` in standalone mode
  B) Two-layer extraction: pure HM modules + NixOS wrappers
- Decision deferred to Task 6 (ultrabrain)

### Hyprland
- Install via pacman on Arch, NOT via Nix
- `wayland.windowManager.hyprland.package = null` in home.nix to use system hyprland

### Theming  
- Use `inputs.stylix.homeModules.stylix` (NOT deprecated `homeManagerModules.stylix`)
- Same Nord theme, dark polarity, opacity 0.85

### Secrets
- Use `inputs.sops-nix.homeManagerModules.sops`
- Paths change: `/run/secrets/` → `/run/user/1000/secrets/` in standalone mode
- `modules/home-manager/cli/mcp.nix` reads `/run/secrets/github_token` — needs update

### Branch
- All work on branch `station-arch-migration` ✅ (created 2026-04-02)
