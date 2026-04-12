# Learnings

## [2026-04-11] Session Init

### Codebase Patterns
- Module option pattern: `options.foo.enable = lib.mkEnableOption "..."` + `config = lib.mkIf config.foo.enable { ... }`
- Host overrides use `lib.mkForce` for hard overrides, plain values for additive
- home-manager user paths: station uses `none`, vnpc-21 uses `odin`
- Section comments in host files: `# ==============================================================================`

### Key File Locations
- AMD GPU module: `modules/nixos/hardware/amd-gpu.nix` (40 lines)
- NVIDIA profile: `profiles/hardware/nvidia.nix` (86 lines) — DO NOT TOUCH
- Shared Hyprland: `modules/home-manager/desktop/hyprland/default.nix`
- Shared zen-browser: `modules/home-manager/misc/zen-browser.nix`
- Station host: `hosts/station/default.nix`
- vnpc-21 host: `hosts/vnpc-21/default.nix`

### Existing home-manager override pattern in vnpc-21 (line 188):
```nix
home-manager.users.odin.services.hypridle.settings.listener = lib.mkAfter [ ... ];
```
