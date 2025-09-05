# Arch Linux Migration

This branch contains configurations for running Arch Linux with Nix and Home Manager, allowing you to maintain your declarative configuration while using Arch as the base system.

## Quick Start

1. **Install Arch Linux** with BTRFS for snapshot support
2. **Clone this repository** and checkout the `arch-migration` branch
3. **Run the bootstrap script**:
   ```bash
   cd nixflake
   ./arch-modules/bootstrap-arch.sh
   ```
4. **Apply Home Manager configuration**:
   ```bash
   home-manager switch --flake .#none@arch-laptop
   ```
5. **Sync Arch packages**:
   ```bash
   arch-sync
   ```

## How It Works

### Dual Package Management
- **Arch (pacman)**: System packages, kernel, drivers, desktop environment
- **Nix**: Development tools, user applications, dotfiles
- **Home Manager**: Manages all user configuration declaratively

### Package Sync System
The `arch-packages.nix` module tracks Arch packages declaratively:
- Lists packages in `~/.config/arch-packages/declared.txt`
- Checks for drift during `home-manager switch`
- Provides commands to sync and manage packages

### Available Commands
- `arch-sync` - Install missing declared packages
- `arch-adopt` - Show untracked packages to add to config
- `arch-status` - Display package management status

## Configuration Structure

```
nixflake/
├── flake.nix                    # Main flake with both NixOS and Arch configs
├── arch-modules/
│   ├── arch-packages.nix       # Arch package management
│   ├── bootstrap-arch.sh       # Initial setup script
│   └── README.md               # This file
├── modules/                     # Existing NixOS modules
└── hosts/                       # NixOS host configurations
```

## Adding Packages

### To track an Arch package:
1. Edit `arch-modules/arch-packages.nix`
2. Add to `commonPackages` (all machines) or `machinePackages.arch-laptop` (laptop only)
3. Run `home-manager switch --flake .#none@arch-laptop`
4. Run `arch-sync` to install

### To install via Nix:
Add to your home-manager configuration as usual.

## Rollback Support

With BTRFS and snapper configured:
- Automatic snapshots before package operations
- Boot from snapshots via GRUB
- Manual rollback: `sudo snapper rollback <number>`

## Switching Between NixOS and Arch

This flake supports both:
- **On NixOS**: `sudo nixos-rebuild switch --flake .#laptop`
- **On Arch**: `home-manager switch --flake .#none@arch-laptop`

## Troubleshooting

### Nix command not found
```bash
newgrp nix-users  # Or log out and back in
```

### Package conflicts
Check which manager owns a package:
```bash
which <command>  # Shows if from /nix or system
```

### Home Manager issues
```bash
nix-channel --update
home-manager switch --flake .#none@arch-laptop --show-trace
```