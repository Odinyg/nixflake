# Omarchy Cherry-Pick Station — Learnings

## Key Technical Findings

### Zen Browser
- Window class: `zen-beta` (immutable — `--name` flag is IGNORED)
- Thunar window class: `Thunar` (capital T)
- Webapp install exec: `zen-beta --new-window URL` (no --name, no --app=)

### NixOS Module Patterns
- `home.activation.<name>` in NixOS modules (not home-manager modules) uses:
  `{ after = ["linkGeneration"]; before = []; data = ''...''; }` — NOT `lib.hm.dag.entryAfter`
- `lib.hm.dag` is only available inside home-manager module context, not NixOS system modules
- `lib.mkAfter [...]` on `wayland.windowManager.hyprland.settings.bind` correctly appends to the merged list across modules — Hyprland uses last-registered-wins for duplicate (modmask, key) pairs

### Hyprland Source= Pattern
- Existing pattern at `default.nix:160-188`: `extraConfig = lib.mkAfter ''source = ~/.config/hypr/overrides.conf''`
- Empty sourced file = no effect (Nix defaults prevail)
- `hyprctl reload` re-reads full config including sourced files; `hyprctl keyword source` is additive and cannot un-set values

### Waybar
- Config is mutable copy deployed ONCE at activation from `waybar-base`
- Subsequent rebuilds skip re-deploy if `~/.config/waybar/` already exists as a real directory
- Station-only patches via jq activation scripts (idempotent via `index("custom/power")` guard)
- CSS uses Catppuccin Macchiato palette (`@red`, `@maroon`, etc.) — NOT Nord
- Nerd Font power glyph: `\uf011` (4 hex digits) in jq strings — NOT `\u{f011}`

### Plan Compliance
- Scripts must be silent on success EXCEPT hyprpicker (runs silently) and power-menu (no success notification either — only error paths notify)
- All external binaries in scripts must use `${pkgs.X}/bin/Y` — shell builtins (printf, cat, mkdir, tr, :) are fine unpinned
- `cut` is NOT a shell builtin — must be `${pkgs.coreutils}/bin/cut`

### VNPC-21 Flake Attr
- Flake attr is uppercase `"VNPC-21"` — shell must quote: `nix eval '.#nixosConfigurations."VNPC-21"...'`

## Commits Produced
- fa93491 feat(station): scaffold omo-helpers module
- a1f8377 feat(omo-helpers): add desktop-UX packages
- 3bdb3e5 feat(omo-helpers): enable cliphist user service
- 1a3e345 feat(omo-helpers): add omo-launch-or-focus script
- 92cb6c0 feat(omo-helpers): add omo-webapp-install script
- 4fa326d feat(omo-helpers): add omo-window-pop script
- de66a48 feat(omo-helpers): add omo-clipboard-pick script
- f5070ef feat(omo-helpers): add omo-emoji-pick script
- d29698c feat(omo-helpers): add omo-power-menu script
- 8eae59e feat(omo-helpers): Hyprland keybinds + Super+W/E override (station-only)
- 1295567 feat(omo-helpers): add animation toggle with sourced state file
- ca0d98c feat(omo-helpers): station-only waybar power icon patch
- fa09900 fix(omo-helpers): use correct home.activation DAG format + fix jq unicode escape
- 057b88f fix(omo-helpers): silent on success + pin cut to coreutils
