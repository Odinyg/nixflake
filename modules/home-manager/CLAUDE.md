# Home-Manager Modules — User-level configuration for desktop machines

System-level (hardware, services, desktop backends) lives in `modules/nixos/` — this layer handles dotfiles, app configs, keybinds, and user-facing tooling.

## Directories
- `cli/` — terminal tools: git, zsh, neovim, tmux, direnv, ghostty, etc.
- `desktop/` — window manager configs: hyprland/ (default.nix + sub-modules)
- `app/` — GUI applications: discord, media players, utilities, communication
- `misc/` — browser, file manager, web-app launchers, scripts

## Canonical Module Template
```nix
{ lib, config, pkgs, ... }:
let
  cfg = config.<name>;
in
{
  options.<name>.enable = lib.mkEnableOption "<description>";
  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    # user-level home-manager config here
  };
}
```

## Rules
- `let cfg = config.<name>;` binding required in every module with an enable option
- Root namespace: `options.<name>` (NOT `options.home.*`)
- Config guard: `lib.mkIf cfg.enable` — always wrapped in `home-manager.users.${config.user}`
- `config.user` and `config.home-manager.*` are cross-module refs — never substitute `cfg`
- Sub-module files (neovim/lsp.nix, hyprland/keybindings.nix, etc.) have NO enable options — config-only, no `let cfg` needed; reference the parent's option directly (e.g., `lib.mkIf config.hyprland.enable`)
- Use `<name>/default.nix` + sub-files only when 3+ sub-module files are needed

## Packages
- `pkgs.*` for stable (nixos-25.05), `pkgs-unstable.*` for newer packages, `inputs.<flake>.packages.*` for flake-sourced packages

## Adding a Module
1. Create file in the appropriate category dir
2. Add import to that category's `default.nix`
3. Enable in a profile (`profiles/home-manager/`) or directly in a host (`hosts/<hostname>/default.nix`)
