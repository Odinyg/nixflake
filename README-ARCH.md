# NixFlake for Arch Linux

Welcome! This branch contains configurations for using this NixOS flake on **Arch Linux** with standalone home-manager.

## 🎯 Quick Start for Arch Users

### One-Line Install (with system dependencies)

```bash
# 1. Install Nix (if not already installed)
sh <(curl -L https://nixos.org/nix/install) --daemon

# 2. Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# 3. Install system dependencies
sudo pacman -S hyprland pipewire pipewire-pulse wireplumber bluez bluez-utils networkmanager xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit qt5-wayland qt6-wayland

# 4. Enable services
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now bluetooth NetworkManager

# 5. Clone and setup
git clone https://github.com/Odinyg/nixflake.git
cd nixflake
git checkout arch  # or the appropriate branch

# 6. Copy and customize your configuration
cp -r arch-hosts/example arch-hosts/$(hostname)
nano arch-hosts/$(hostname)/home.nix  # Change username

# 7. Add your config to flake.nix (edit the homeConfigurations section)

# 8. Build and activate
nix run home-manager/master -- switch --flake .#yourusername@$(hostname)
```

## 📖 Full Documentation

See **[ARCH-SETUP.md](./ARCH-SETUP.md)** for complete installation and configuration guide.

## 🔑 Key Differences from NixOS

| Aspect | NixOS Version | Arch Version |
|--------|---------------|--------------|
| Configuration | `nixosConfigurations` in flake | `homeConfigurations` in flake |
| System packages | NixOS manages everything | Arch pacman for system, Nix for user |
| Rebuild command | `nixos-rebuild` | `home-manager` |
| Boot loader | Managed by Nix | Managed by Arch/GRUB |
| System services | NixOS modules | Arch systemd |
| Justfile | `justfile` (nixos) | `justfile-arch` (rename to justfile) |

## 📁 Arch-Specific Files

```
.
├── arch-hosts/              # Arch Linux configurations
│   └── example/            # Example configuration
│       └── home.nix        # Home-manager config
├── profiles/home-manager/   # Reusable home-manager profiles
│   └── base.nix            # Base profile for standalone
├── justfile-arch           # Arch-specific build commands
├── ARCH-SETUP.md           # Detailed setup guide
└── README-ARCH.md          # This file
```

## 🚀 Daily Usage

### Using Justfile (Recommended)

```bash
# Copy the Arch justfile
cp justfile-arch justfile

# Rebuild your configuration
just rebuild

# Update and rebuild
just upgrade

# Clean old generations
just gc

# List all available commands
just --list
```

### Manual Commands

```bash
# Switch to new configuration
home-manager switch --flake .#yourusername@yourhostname

# Build without switching
home-manager build --flake .#yourusername@yourhostname

# Update inputs
nix flake update

# Rollback
home-manager generations
home-manager switch --flake .#yourusername@yourhostname --rollback
```

## ✨ What You Get

### Working on Arch
✅ All CLI tools (neovim, zsh, git, etc.)  
✅ Desktop environment configs (Hyprland, waybar, rofi)  
✅ User applications (browsers, Discord, etc.)  
✅ Development tools and LSPs  
✅ Theming via Stylix (Nord theme)  
✅ Dotfiles management  
✅ Reproducible user environment  

### Managed by Arch
🔧 System services (NetworkManager, Bluetooth)  
🔧 Hardware drivers and firmware  
🔧 Boot loader and kernel  
🔧 System-wide packages  

## 🎨 Available Modules

All home-manager modules from `modules/home-manager/` are available:

**Desktop Environments:**
- Hyprland (primary)
- BSPWM (alternative)
- COSMIC (experimental)

**CLI Tools:**
- Neovim with full IDE setup
- Zsh with oh-my-zsh
- Kitty terminal
- Zellij multiplexer
- Git with lazygit

**Development:**
- Language servers (Nix, Python, Go, Rust, TypeScript, etc.)
- Docker (install via pacman)
- Direnv
- Various development tools

**Applications:**
- Chromium/Firefox
- Discord
- Thunar file manager
- Media players

**Theming:**
- Stylix with Nord theme
- Custom fonts
- Consistent theming across all apps

## 🔧 Configuration

Enable modules in your `arch-hosts/yourhostname/home.nix`:

```nix
{
  # Desktop
  hyprland.enable = true;
  
  # Terminal
  neovim.enable = true;
  zsh.enable = true;
  kitty.enable = true;
  
  # Development
  git.enable = true;
  languages.enable = true;
  
  # Apps
  discord.enable = true;
  chromium.enable = true;
  
  # Theme
  styling.enable = true;
  styling.theme = "nord";
}
```

## 🐛 Troubleshooting

**Home-manager not found:**
```bash
nix run home-manager/master -- init
```

**Flake errors:**
```bash
nix flake check
```

**Hyprland not starting:**
```bash
sudo pacman -S hyprland  # Ensure installed via pacman
```

**Audio issues:**
```bash
systemctl --user restart pipewire pipewire-pulse
```

## 📚 Resources

- [Full Setup Guide](./ARCH-SETUP.md) - Detailed installation instructions
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nixpkgs Search](https://search.nixos.org/packages)
- [Original README](./README.md) - For NixOS users

## 🤝 Contributing

This branch is specifically for Arch Linux support. For NixOS-specific changes, please use the main branch.

## 📝 Notes

- System services must be installed via `pacman` and enabled with `systemctl`
- Hyprland, audio (PipeWire), and other system components are managed by Arch
- Only user-level configuration is managed by home-manager
- You get the best of both worlds: Arch's simplicity with Nix's reproducibility

## 💡 Tips

1. **Keep Arch Updated:** Run `sudo pacman -Syu` regularly
2. **Update Nix Packages:** Run `just upgrade` or `nix flake update`
3. **Backup Your Config:** Your entire user environment is in this repo - commit changes!
4. **Multiple Machines:** Clone this repo on any Arch machine for instant environment replication
5. **Experiment Safely:** home-manager keeps generations, so you can always rollback

---

**Happy Nix-ing on Arch! 🎉**
