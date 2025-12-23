# Arch Linux Documentation Index

Complete guide to using this NixOS flake on Arch Linux with home-manager.

## 📚 Documentation Overview

| Document | Purpose | Best For |
|----------|---------|----------|
| **[ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md)** | 5-minute setup guide | Experienced users who want to get started quickly |
| **[ARCH-SETUP.md](./ARCH-SETUP.md)** | Comprehensive setup guide | First-time users who need detailed instructions |
| **[ARCH-CHECKLIST.md](./ARCH-CHECKLIST.md)** | Step-by-step checklist | Users who want to track their progress |
| **[README-ARCH.md](./README-ARCH.md)** | Overview and daily usage | Users familiar with the setup who need a reference |
| **[NIXOS-TO-ARCH.md](./NIXOS-TO-ARCH.md)** | Migration guide | Users moving from NixOS to Arch |
| **[arch-hosts/README.md](./arch-hosts/README.md)** | Configuration guide | Users creating or modifying host configs |

## 🚀 Getting Started

### Choose Your Path

**New to Nix?**
1. Start with [ARCH-CHECKLIST.md](./ARCH-CHECKLIST.md)
2. Follow step-by-step instructions
3. Refer to [ARCH-SETUP.md](./ARCH-SETUP.md) for details

**Experienced with Nix?**
1. Jump to [ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md)
2. Copy-paste the commands
3. You're done!

**Migrating from NixOS?**
1. Read [NIXOS-TO-ARCH.md](./NIXOS-TO-ARCH.md)
2. Follow the migration steps
3. Keep your existing configurations

## 📖 Document Details

### ARCH-QUICKSTART.md
**Quick 5-step installation guide**
- Copy-paste ready commands
- Minimal explanations
- Get up and running in 10 minutes
- Best for: Experienced Linux users

**Sections:**
- Prerequisites
- One-line installations
- Daily usage commands
- Quick customization

### ARCH-SETUP.md
**Complete setup and configuration guide**
- Detailed explanations
- Troubleshooting tips
- Configuration examples
- Best for: First-time Nix users

**Sections:**
1. Overview
2. Installation steps (detailed)
3. Configuration structure
4. Daily usage
5. Troubleshooting
6. Advanced topics

### ARCH-CHECKLIST.md
**Interactive checklist**
- Step-by-step tasks
- Verification steps
- Troubleshooting checklist
- Best for: Methodical users

**Phases:**
1. Pre-installation checks
2. Install Nix
3. Install system dependencies
4. Clone configuration
5. Create your config
6. Update flake
7. Build and activate
8. Shell integration
9. Verification
10. Test desktop environment

### README-ARCH.md
**Daily reference guide**
- Quick overview
- Common commands
- Configuration tips
- Best for: Regular users

**Sections:**
- Quick start summary
- Key differences from NixOS
- Available modules
- Troubleshooting
- Tips and tricks

### NIXOS-TO-ARCH.md
**Migration guide from NixOS**
- Why migrate?
- Step-by-step migration
- Configuration differences
- Best for: NixOS users

**Sections:**
1. Why migrate?
2. Prepare on NixOS
3. Install Arch
4. Setup hardware
5. Install Nix and home-manager
6. Restore environment
7. Configuration differences
8. Module availability

### arch-hosts/README.md
**Host configuration guide**
- Creating configs
- Module usage
- Examples
- Best for: Configuration authors

**Sections:**
- Directory structure
- Creating new configurations
- Available profiles
- Module configuration
- Multiple configurations
- Examples (minimal, full workstation)

## 🎯 Common Tasks

### Installing Fresh on Arch
1. [ARCH-CHECKLIST.md](./ARCH-CHECKLIST.md) - Follow the checklist
2. [ARCH-SETUP.md](./ARCH-SETUP.md) - Reference for details

### Quick Setup
1. [ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md) - Copy-paste commands

### Migrating from NixOS
1. [NIXOS-TO-ARCH.md](./NIXOS-TO-ARCH.md) - Complete migration guide

### Configuring Your System
1. [arch-hosts/README.md](./arch-hosts/README.md) - Configuration guide
2. [README-ARCH.md](./README-ARCH.md) - Module reference

### Daily Usage
1. [README-ARCH.md](./README-ARCH.md) - Common commands and tips

### Troubleshooting
1. [ARCH-SETUP.md](./ARCH-SETUP.md) - Troubleshooting section
2. [ARCH-CHECKLIST.md](./ARCH-CHECKLIST.md) - Troubleshooting checklist
3. [README-ARCH.md](./README-ARCH.md) - Common issues

## 🔍 Finding Specific Information

### Installation Questions
- **How do I install Nix?** → [ARCH-SETUP.md § Installation](./ARCH-SETUP.md#installation-steps)
- **What system packages do I need?** → [ARCH-CHECKLIST.md § Phase 2](./ARCH-CHECKLIST.md#phase-2-install-system-dependencies)
- **Quick installation commands?** → [ARCH-QUICKSTART.md § Installation](./ARCH-QUICKSTART.md#installation-copy-paste-ready)

### Configuration Questions
- **How do I create a config?** → [arch-hosts/README.md § Creating](./arch-hosts/README.md#creating-a-new-configuration)
- **What modules are available?** → [README-ARCH.md § Modules](./README-ARCH.md#-available-modules)
- **How do I enable modules?** → [arch-hosts/README.md § Modules](./arch-hosts/README.md#module-configuration)

### Usage Questions
- **How do I rebuild?** → [README-ARCH.md § Daily Usage](./README-ARCH.md#-daily-usage)
- **How do I update?** → [README-ARCH.md § Daily Usage](./README-ARCH.md#-daily-usage)
- **Available justfile commands?** → [README-ARCH.md § Using Justfile](./README-ARCH.md#using-justfile-recommended)

### Troubleshooting Questions
- **Nix not found?** → [ARCH-SETUP.md § Troubleshooting](./ARCH-SETUP.md#troubleshooting)
- **Audio not working?** → [ARCH-CHECKLIST.md § Troubleshooting](./ARCH-CHECKLIST.md#troubleshooting-checklist)
- **Hyprland won't start?** → [ARCH-SETUP.md § Troubleshooting](./ARCH-SETUP.md#hyprland-not-starting)

### Advanced Topics
- **Multiple profiles?** → [ARCH-SETUP.md § Advanced](./ARCH-SETUP.md#multiple-profiles)
- **Nix shell for development?** → [ARCH-SETUP.md § Advanced](./ARCH-SETUP.md#using-nix-shell-for-development)
- **Configuration differences?** → [NIXOS-TO-ARCH.md § Differences](./NIXOS-TO-ARCH.md#configuration-differences)

## 📋 Reading Order

### For First-Time Users
1. [README-ARCH.md](./README-ARCH.md) - Get an overview
2. [ARCH-CHECKLIST.md](./ARCH-CHECKLIST.md) - Follow the checklist
3. [ARCH-SETUP.md](./ARCH-SETUP.md) - Reference for details
4. [arch-hosts/README.md](./arch-hosts/README.md) - Learn about configuration

### For Experienced Users
1. [ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md) - Quick setup
2. [README-ARCH.md](./README-ARCH.md) - Daily reference
3. [arch-hosts/README.md](./arch-hosts/README.md) - Configuration reference

### For NixOS Migrants
1. [NIXOS-TO-ARCH.md](./NIXOS-TO-ARCH.md) - Complete migration
2. [README-ARCH.md](./README-ARCH.md) - New workflow reference
3. [arch-hosts/README.md](./arch-hosts/README.md) - Configuration differences

## 🎓 Learning Path

### Beginner (New to Nix)
**Goal:** Get a working system with Nix on Arch

1. **Understand the concepts** - [README-ARCH.md § Overview](./README-ARCH.md)
2. **Install step-by-step** - [ARCH-CHECKLIST.md](./ARCH-CHECKLIST.md)
3. **Learn configuration** - [arch-hosts/README.md](./arch-hosts/README.md)
4. **Daily usage** - [README-ARCH.md § Daily Usage](./README-ARCH.md#-daily-usage)

### Intermediate (Familiar with Nix)
**Goal:** Customize and optimize your setup

1. **Quick setup** - [ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md)
2. **Module configuration** - [arch-hosts/README.md § Modules](./arch-hosts/README.md#module-configuration)
3. **Advanced topics** - [ARCH-SETUP.md § Advanced](./ARCH-SETUP.md#advanced-topics)

### Advanced (NixOS User)
**Goal:** Migrate efficiently and understand differences

1. **Migration guide** - [NIXOS-TO-ARCH.md](./NIXOS-TO-ARCH.md)
2. **Differences** - [NIXOS-TO-ARCH.md § Differences](./NIXOS-TO-ARCH.md#configuration-differences)
3. **Best practices** - [NIXOS-TO-ARCH.md § Best Practices](./NIXOS-TO-ARCH.md#best-practices)

## 🔗 Quick Links

### Essential Commands
```bash
# Installation
sh <(curl -L https://nixos.org/nix/install) --daemon

# Build configuration
home-manager switch --flake .#$USER@$(hostname)

# Rebuild with justfile
just rebuild

# Update packages
just upgrade

# Clean old generations
just gc
```

### Important Files
- `flake.nix` - Main configuration entry point
- `arch-hosts/$(hostname)/home.nix` - Your host configuration
- `justfile` - Build commands (copy from `justfile-arch`)
- `~/.config/nix/nix.conf` - Nix settings

### Useful Directories
- `arch-hosts/` - Arch Linux configurations
- `profiles/home-manager/` - Reusable profiles
- `modules/home-manager/` - Available modules

## 🆘 Getting Help

1. **Check the docs** - Use this index to find relevant documentation
2. **Search the wiki** - [Arch Wiki](https://wiki.archlinux.org/)
3. **Read home-manager manual** - [Home-manager Manual](https://nix-community.github.io/home-manager/)
4. **Check Nix manual** - [Nix Manual](https://nixos.org/manual/nix/)

## 📝 Additional Resources

### External Documentation
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Manual](https://nixos.org/manual/nix/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/)
- [Hyprland Wiki](https://wiki.hyprland.org/)

### Package Search
- [Nixpkgs Search](https://search.nixos.org/packages)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)

### Community
- [Nix Discourse](https://discourse.nixos.org/)
- [r/NixOS](https://reddit.com/r/NixOS)
- [Arch Linux Forums](https://bbs.archlinux.org/)

## 🎉 Quick Start Summary

**Absolute minimum to get started:**

```bash
# 1. Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# 2. Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# 3. Install system deps
sudo pacman -S hyprland pipewire networkmanager

# 4. Enable services
systemctl --user enable --now pipewire
sudo systemctl enable --now NetworkManager

# 5. Clone and setup
git clone https://github.com/Odinyg/nixflake.git
cd nixflake
git checkout copilot/set-up-arch-with-nix

# 6. Configure
cp -r arch-hosts/example arch-hosts/$(hostname)
sed -i "s/youruser/$USER/g" arch-hosts/$(hostname)/home.nix

# 7. Build
nix run home-manager/master -- switch --flake .#$USER@$(hostname)
```

**Then read:** [README-ARCH.md](./README-ARCH.md) for daily usage.

---

**Happy Nix-ing on Arch! 🚀**
