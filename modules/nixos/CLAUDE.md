# Desktop/System Modules — NixOS + Home-Manager

## Module Layers
- `modules/nixos/` — system-level: hardware, services, desktop backends, security
- `modules/home-manager/` — user-level: CLI tools, desktop configs, apps, theming
- Home-manager wraps config in `config.home-manager.users.${config.user}` — the `user` variable comes from the host config

## Adding a Module
1. Create in `modules/nixos/` (system) or `modules/home-manager/<category>/` (user)
2. Add import to the category's `default.nix`
3. Enable in a profile (`profiles/`) or directly in a host (`hosts/<hostname>/default.nix`)

## Desktop Environments
- **Hyprland** (primary): system backend in `nixos/hyprland.nix`, user config in `home-manager/desktop/hyprland/`
- **COSMIC**: system-only in `nixos/cosmic.nix`, no home-manager config needed
- **BSPWM**: X11-based alternative in `home-manager/desktop/bspwm/`
- Hyprland sub-modules: `monitors.nix`, `keybindings.nix`, `services.nix`, `hyprpanel.nix`, `packages.nix`
- System-level options (e.g., `config.hyprland.monitors`) are read by home-manager modules

## Theming
- Stylix handles all theming — Nord theme, dark polarity, auto-applies to GTK/QT/apps
- Config in `modules/nixos/styling.nix`, defaults in `profiles/base.nix`
- Individual hosts override via `styling.opacity.terminal`, `styling.cursor.size`, etc.
- Do NOT set colors manually in app configs — Stylix manages this

## Neovim (nixvim)
- Declarative config in `home-manager/cli/neovim/`
- Sub-modules per concern: `lsp.nix`, `cmp.nix`, `telescope.nix`, `harpoon.nix`, etc.
- Plugin modules have NO option definitions — they directly set `programs.nixvim.plugins.*`

## Rules
- IMPORTANT: Nested options are common — e.g., `gaming.steam.enable`, `gaming.performance.gamemode`
- Profiles group module enables for host types — prefer adding to profiles over individual hosts
- Home-manager is desktop-only (via `mkHost`) — servers never have it
