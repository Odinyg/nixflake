# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modular NixOS flake configuration repository that manages system configurations for multiple hosts with home-manager integration. It uses Nix flakes for reproducible system configurations and supports multiple desktop environments (primarily Hyprland, with BSPWM and COSMIC as alternatives).

## Key Commands

### System Rebuild Commands
```bash
# Rebuild current host (detects hostname automatically)
just rebuild

# Rebuild with verbose output
just verbose

# Update flake inputs and rebuild
just upgrade

# Build new boot configuration without switching
just boot

# Clean old generations (14+ days)
just gc

# Manual rebuild for specific host
sudo nixos-rebuild switch --flake .#<hostname>
```

### Development Commands
```bash
# View changes excluding flake.lock
just diff

# Add all .nix files to git (auto-run before rebuild)
git add *.nix
```

## Architecture

### Module System
The configuration follows a hierarchical module structure:

1. **Top Level (`flake.nix`)**: Defines hosts and imports common modules
2. **Modules Layer (`modules/`)**: Split into two main categories:
   - `nixos/`: System-level configurations (services, hardware, boot)
   - `home-manager/`: User-level configurations (apps, dotfiles, desktop)

### Host Configuration Pattern
Each host in `hosts/` contains:
- `default.nix`: Main host configuration with enabled modules
- `hardware-configuration.nix`: Hardware-specific settings
- `home.nix` (optional): Host-specific home-manager overrides

### Module Enable Pattern
Most features use a boolean enable pattern:
```nix
moduleName.enable = true;  # Enables the module
```

### Key Module Categories

**System Modules (`modules/nixos/`):**
- Hardware configurations (GPU, audio, bluetooth, wireless)
- System services (Tailscale, Syncthing, virtualization)
- Desktop environment backends (Hyprland, COSMIC)
- Security (polkit, secrets management via sops-nix)

**Home Manager Modules (`modules/home-manager/`):**
- CLI tools (neovim/nixvim, zsh, git, terminal utilities)
- Desktop environments (Hyprland config, waybar, rofi)
- Applications (browsers, communication, productivity)
- Theming (managed by Stylix with Nord theme)

### Configuration Hierarchy
1. Host defines base settings and user
2. Modules define options with defaults
3. Host can override any module option
4. Home-manager configs are per-user

## Important Files and Locations

### Hyprland Wallpaper Management
- Wallpapers: `modules/home-manager/desktop/hyprland/config/wallpapers/`
- Random wallpaper script: `modules/home-manager/desktop/hyprland/scripts/random-wallpaper.sh`
- Note: Hyprpaper configs should NOT use quotes around file paths

### Neovim Configuration
- Main config: `modules/home-manager/cli/neovim/`
- Uses nixvim for declarative Neovim configuration
- Includes LSP, completion, formatting, and various plugins

### Desktop Environment Configs
- Hyprland: `modules/home-manager/desktop/hyprland/`
- BSPWM: `modules/home-manager/desktop/bspwm/`
- Waybar: `modules/home-manager/desktop/hyprland/config/waybar/`

## Working with This Repository

### Adding New Modules
1. Create module file in appropriate directory
2. Add to relevant `default.nix` imports
3. Use the enable pattern for optional features
4. Test with `just rebuild`

### Modifying Configurations
1. Most user-facing configs are in `modules/home-manager/`
2. System services in `modules/nixos/`
3. Host-specific overrides in `hosts/<hostname>/`
4. Run `just rebuild` to apply changes

### Debugging
- Use `just verbose` for detailed rebuild output
- Check `journalctl -xe` for service errors
- Hyprland logs: `~/.local/share/hyprland/`
- Previous generations: `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`

## Notes

- The repository uses Stylix for consistent theming (Nord theme)
- Flake inputs are pinned in `flake.lock` for reproducibility
- Secrets are managed with sops-nix (see `secrets/secrets.yaml`)
- The system supports multiple users but primarily configured for user "odin" on VNPC-21 host

## Git Commit Guidelines

- Do NOT add Claude Code signatures or Co-Authored-By lines to commits
- Keep commit messages concise and descriptive
- Focus on what changed, not implementation details