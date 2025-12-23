# Arch Linux Setup with Nix and Home-Manager

This guide explains how to use this NixOS flake configuration on Arch Linux with standalone home-manager. This allows you to manage your user environment, dotfiles, and applications with Nix while keeping Arch as your base system.

## Overview

**What This Setup Provides:**
- User environment management via home-manager
- Declarative configuration for dotfiles, applications, and development tools
- Access to Nixpkgs repositories (80,000+ packages)
- Reproducible user environment across machines
- All home-manager modules from this repository

**What Stays on Arch:**
- System-level configuration (boot loader, kernel, systemd services)
- Hardware drivers and firmware
- System-wide services (NetworkManager, Bluetooth, PipeWire)
- Base system packages

## Prerequisites

- Arch Linux installed and running
- Internet connection
- `curl` and `git` installed: `sudo pacman -S curl git`

## Installation Steps

### 1. Install Nix Package Manager

```bash
# Install Nix in multi-user mode (recommended)
sh <(curl -L https://nixos.org/nix/install) --daemon

# After installation, restart your shell or run:
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 2. Enable Flakes Support

Create or edit `~/.config/nix/nix.conf`:

```bash
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
EOF
```

### 3. Install System Dependencies

These must be installed via pacman as they require system-level integration:

```bash
# Desktop environment (Hyprland)
sudo pacman -S hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Audio system
sudo pacman -S pipewire pipewire-pulse wireplumber

# Bluetooth
sudo pacman -S bluez bluez-utils

# Networking
sudo pacman -S networkmanager

# Display manager (optional, choose one)
sudo pacman -S sddm  # or greetd, ly, etc.

# Other system components
sudo pacman -S polkit qt5-wayland qt6-wayland
```

### 4. Enable Required System Services

```bash
# Enable and start audio services
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Enable system services
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager

# Enable display manager (if using)
sudo systemctl enable sddm
```

### 5. Clone This Repository

```bash
cd ~
git clone https://github.com/Odinyg/nixflake.git
cd nixflake

# Switch to the arch branch
git checkout arch  # or copilot/set-up-arch-with-nix
```

### 6. Create Your Host Configuration

```bash
# Copy the example configuration
cp -r arch-hosts/example arch-hosts/$(hostname)

# Edit the configuration
nano arch-hosts/$(hostname)/home.nix
```

Update the username in `home.nix`:
```nix
home.username = "yourusername";  # Change this to your actual username
home.homeDirectory = "/home/yourusername";
```

### 7. Update flake.nix with Your Configuration

Edit `flake.nix` and add your configuration to the `homeConfigurations` section:

```nix
homeConfigurations = {
  # Replace with your username and hostname
  "yourusername@yourhostname" = mkStandaloneHomeConfig {
    username = "yourusername";
    stateVersion = "25.05";
    hostname = "yourhostname";
    extraModules = [ ./arch-hosts/yourhostname/home.nix ];
  };
};
```

### 8. Build and Activate Home-Manager Configuration

```bash
# First time: Install home-manager
nix run home-manager/master -- init

# Build and switch to your configuration
nix run home-manager/master -- switch --flake .#yourusername@yourhostname

# Or if using the justfile-arch:
cp justfile-arch justfile
just rebuild
```

### 9. Configure Your Shell

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Source Nix profile
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Source home-manager session variables
if [ -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
  . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
fi
```

Restart your shell or source the file:
```bash
source ~/.bashrc  # or ~/.zshrc
```

## Daily Usage

### Using the Justfile

If you copied `justfile-arch` to `justfile`:

```bash
# Rebuild home-manager configuration
just rebuild

# Update flake inputs and rebuild
just upgrade

# Clean old generations
just gc

# List all generations
just generations

# Check for errors
just check
```

### Manual Commands

```bash
# Switch to a new configuration
home-manager switch --flake .#yourusername@yourhostname

# Build without switching (for testing)
home-manager build --flake .#yourusername@yourhostname

# Update flake inputs
nix flake update

# Rollback to previous generation
home-manager generations  # List generations
home-manager switch --flake .#yourusername@yourhostname --rollback
```

## Configuration Structure

### What Modules Work on Arch

✅ **Working (via home-manager):**
- All CLI tools (neovim, zsh, git, etc.)
- Desktop environment configurations (Hyprland, waybar, rofi)
- User applications (browsers, discord, etc.)
- Development tools and language servers
- Theming via Stylix
- Dotfiles management
- User-level systemd services

❌ **Not Available (NixOS-specific):**
- Boot loader configuration
- Kernel modules
- System services (use Arch's systemd)
- System users and groups
- Hardware configuration (use Arch tools)
- Firewall (use Arch's firewall)

### Available Modules

Check `modules/home-manager/` for all available modules:

```
modules/home-manager/
├── app/          # GUI applications (discord, chromium, etc.)
├── cli/          # Terminal tools (neovim, zsh, git, etc.)
├── desktop/      # Desktop environments (hyprland, bspwm, cosmic)
└── misc/         # Miscellaneous configs
```

Enable modules in your `arch-hosts/yourhostname/home.nix`:

```nix
{
  # Desktop environment
  hyprland.enable = true;
  
  # Terminal tools
  neovim.enable = true;
  zsh.enable = true;
  kitty.enable = true;
  
  # Development tools
  git.enable = true;
  direnv.enable = true;
  languages.enable = true;
  
  # Applications
  discord.enable = true;
  chromium.enable = true;
  
  # Theming
  styling.enable = true;
  styling.theme = "nord";
}
```

## Troubleshooting

### Nix daemon not running

```bash
sudo systemctl status nix-daemon
sudo systemctl start nix-daemon
```

### Home-manager not found

```bash
# Install home-manager
nix run home-manager/master -- init
```

### Flake evaluation errors

```bash
# Check syntax
nix flake check

# Show detailed error
nix flake show --verbose
```

### Module not found errors

Make sure you're importing the right modules. For Arch, use:
```nix
imports = [
  ../../modules/home-manager  # Not ../../modules
];
```

### Hyprland not starting

Make sure Hyprland is installed via pacman:
```bash
sudo pacman -S hyprland
```

Home-manager only manages the configuration, not the Hyprland package itself on Arch.

### Audio not working

```bash
# Check PipeWire status
systemctl --user status pipewire pipewire-pulse

# Restart audio services
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Differences from NixOS Setup

| Feature | NixOS | Arch + Nix |
|---------|-------|------------|
| System config | Declarative | Traditional Arch |
| Package management | Nix only | pacman + Nix |
| User environment | home-manager | home-manager |
| System services | NixOS modules | Arch systemd |
| Boot loader | Managed by Nix | Managed by Arch |
| Kernel | Managed by Nix | Managed by pacman |

## Updating

### Update Flake Inputs

```bash
nix flake update
just rebuild
```

### Update System Packages (Arch)

```bash
sudo pacman -Syu
```

Both should be done regularly and independently.

## Backing Up and Restoring

Your configuration is in this repository. To replicate on another machine:

1. Install Arch Linux
2. Install Nix
3. Clone this repository
4. Run `home-manager switch --flake .#yourusername@newhostname`

All your user environment, dotfiles, and applications will be restored!

## Advanced Topics

### Multiple Profiles

You can create multiple home-manager profiles for different use cases:

```nix
# In flake.nix
homeConfigurations = {
  "user@work" = mkStandaloneHomeConfig {
    username = "user";
    extraModules = [ ./arch-hosts/work/home.nix ];
  };
  "user@personal" = mkStandaloneHomeConfig {
    username = "user";
    extraModules = [ ./arch-hosts/personal/home.nix ];
  };
};
```

Switch between them:
```bash
home-manager switch --flake .#user@work
home-manager switch --flake .#user@personal
```

### Using Nix Shell for Development

Create project-specific environments:

```bash
# Create a shell.nix or flake.nix in your project
nix-shell  # or nix develop

# Or use nix-shell for quick environments
nix-shell -p python3 nodejs
```

### Installing Additional Packages

Add to your `home.nix`:

```nix
home.packages = with pkgs; [
  package-name
  another-package
];
```

## Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nixpkgs Search](https://search.nixos.org/packages)
- [Arch Wiki](https://wiki.archlinux.org/)
- [Hyprland Wiki](https://wiki.hyprland.org/)

## Getting Help

- Check `just --list` for available commands
- Run `nix flake check` to validate configuration
- Check logs: `journalctl --user -u home-manager-*`
- Home-manager issues: `home-manager --help`
