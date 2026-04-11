# Learnings — hyprland-mutable-overrides

## Architecture
- Hyprland config: `wayland.windowManager.hyprland.settings` (Nix attrs) in `default.nix`
- `extraConfig` merges as `lib.types.lines` — string concatenation. Multiple modules write to it.
- `monitors.nix` writes monitor/workspace defaults to `extraConfig`
- `hosts/station/default.nix:192-200` also writes workspace gap rules to `extraConfig`
- Must use `lib.mkAfter` for source line to guarantee it appears LAST in generated config
- Waybar: single directory symlink at `xdg.configFile."waybar"` → `./config/waybar`
- Rofi: 3 chained files — `config.rasi` → `@theme "nord"` → `nord.rasi` → `@import "rounded-common.rasi"` — ALL 3 must move together
- `home.activation` is new pattern — no existing usage in codebase
- Activation hook: `lib.hm.dag.entryAfter [ "writeBoundary" ]` runs after Nix writes managed files

## Users per host
- laptop/station: user `none`
- vnpc-21: user `odin`
- All paths MUST use `$HOME`, never `/home/none`

## Nix Eval hosts
- laptop: `nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath`
- station: `nix eval .#nixosConfigurations.station.config.system.build.toplevel.drvPath`
- VNPC-21: `nix eval .#nixosConfigurations.VNPC-21.config.system.build.toplevel.drvPath`
