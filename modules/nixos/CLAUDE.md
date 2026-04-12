# Desktop/System Modules — NixOS + Home-Manager

## Module Layers
- `modules/nixos/` — system-level: hardware, services, desktop backends, security
  - `hardware/` — GPU, audio, bluetooth, NAS mounts, wireless
  - `work/` — communication, dev tools, productivity, remote access (cascade-enables sub-modules)
  - `hosted-services/` — self-hosted services on desktop (n8n, open-webui)
- `modules/home-manager/` — user-level: CLI tools, desktop configs, apps, theming
- Home-manager wraps config in `config.home-manager.users.${config.user}` — `user` comes from host config

## Adding a Module
1. Create in `modules/nixos/` (system) or `modules/home-manager/<category>/` (user)
2. Add import to the category's `default.nix`
3. Enable in a profile (`profiles/`) or directly in a host (`hosts/<hostname>/default.nix`)

## Desktop Environments
- **Hyprland** (primary): system backend in `nixos/hyprland.nix`, user config in `home-manager/desktop/hyprland/`
- **COSMIC**: system-only in `nixos/cosmic.nix`, no home-manager config needed
- Status bars: both **Waybar** and **HyprPanel** — waybar config in `hyprland/config/waybar/`, hyprpanel in `hyprpanel.nix`

## Theming
- Stylix handles all theming — Nord theme, dark polarity, auto-applies to GTK/QT/apps
- Config in `modules/nixos/styling.nix`, defaults in `profiles/base.nix`
- Do NOT set colors manually in app configs — Stylix manages this

## Neovim (nixvim)
- Declarative config in `home-manager/cli/neovim/` — plugin modules set `programs.nixvim.plugins.*` directly, no options

## Canonical Module Template
```nix
{ lib, config, pkgs, ... }:
let
  cfg = config.<name>;
in
{
  options.<name>.enable = lib.mkEnableOption "<description>";
  config = lib.mkIf cfg.enable {
    # system-level config
  };
}
```

## Rules
- IMPORTANT: `let cfg = config.<name>;` is MANDATORY in every module with an enable option
- IMPORTANT: Config guard is ALWAYS `lib.mkIf cfg.enable` — never use inline `config.<name>.enable`
- Cross-module refs (`config.user`, `config.sops.*`, `config.smbmount.*`) stay as `config.X` — never replace with `cfg`
- `with lib;` is NOT used — always explicit `lib.mkIf`, `lib.mkOption`, etc.
- Nested options are common — e.g., `gaming.steam.enable`, `gaming.performance.gamemode`
- Profiles group module enables for host types — prefer adding to profiles over individual hosts
- Home-manager is desktop-only (via `mkHost`) — servers never have it
