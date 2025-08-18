# NixOS Configuration

A modular NixOS flake configuration supporting multiple hosts and desktop environments with home-manager integration.

## 🖥️ Hosts

| Host | Description | Desktop | Hardware |
|------|-------------|---------|----------|
| **laptop** | Personal laptop | Hyprland | Generic laptop |
| **station** | Desktop workstation | Hyprland | AMD desktop |

## ✨ Features

### Desktop Environments
- **Hyprland** - Modern Wayland compositor (primary)
- **BSPWM** - Tiling window manager for X11
- **COSMIC** - System76's desktop environment (Posible future primary desktop)

### Development Setup
- **Neovim** with nixvim configuration (LSP, completion, plugins)
- **Zellij** terminal multiplexer (mostly stock configuration)
- **Zsh** with oh-my-zsh and custom aliases
- **Git** with lazygit integration
- **Direnv** for project environments
- **Docker** with rootless configuration

### Applications & Tools
- **Terminal**: Kitty with custom configuration
- **File Manager**: Thunar with archive support
- **Browsers**: Zen Browser, Brave
- **Communication**: Discord (Vesktop), Teams
- **Productivity**: Obsidian, LibreOffice
- **Development**: Language servers, formatters, linters for multiple languages

### System Features
- **Stylix** for consistent theming (Nord theme)
- **Home Manager** for user configuration
- **Tailscale** for VPN networking
- **Syncthing** for file synchronization
- **Audio**: PipeWire with PulseAudio compatibility
- **Virtualization**: Docker, QEMU/KVM, VirtualBox, virt-manager
- **Security**: SOPS-nix for secrets management

## 🚀 Quick Start

### Prerequisites
- NixOS installed
- Flakes enabled in your Nix configuration

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Odinyg/nixflake.git
   cd nixflake
   ```

2. **Build and switch** (replace `<host>` with your target host)
   ```bash
   sudo nixos-rebuild switch --flake .#<host>
   ```

3. **Available commands** (using justfile)
   ```bash
   # Rebuild current host (auto-detects hostname)
   just rebuild
   
   # Update flake inputs and rebuild
   just upgrade
   
   # Rebuild into new bootable generation
   just boot
   
   # Verbose rebuild for debugging
   just verbose
   
   # Clean old generations (14+ days)
   just gc
   
   # View changes excluding flake.lock
   just diff
   ```

## 📁 Structure

```
.
├── flake.nix                 # Main flake configuration
├── justfile                  # Build commands
├── hosts/                    # Host-specific configurations
│   ├── laptop/
│   ├── p53/
│   └── station/
└── modules/                  # Modular configuration
    ├── home-manager/         # User configurations
    │   ├── app/              # Applications
    │   ├── cli/              # Command-line tools
    │   ├── desktop/          # Desktop environments
    │   └── misc/             # Miscellaneous
    └── nixos/                # System configurations
        ├── hardware/         # Hardware-specific modules
        └── *.nix            # System services
```

## ⚙️ Configuration

### Adding a New Host

1. Create a new directory in `hosts/`
2. Add `default.nix` and `hardware-configuration.nix`
3. Create a `home.nix` for home-manager
4. Add the host to `flake.nix`

Example:
```nix
# In flake.nix
myhost = nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs system; };
  modules = [
    ./hosts/myhost
    ./modules
    # ... other modules
  ];
};
```

### Enabling/Disabling Features

Most features are controlled by boolean options:

```nix
# In your host configuration
neovim.enable = true;
hyprland.enable = true;
discord.enable = false;
```

### Desktop Environment Switching

The configuration supports multiple desktop environments:

```nix
# Hyprland (Wayland)
hyprland.enable = true;

# BSPWM (X11)
bspwm.enable = true;
rofi.enable = true;

# COSMIC
services.desktopManager.cosmic.enable = true;
```

## 🎨 Theming

The configuration uses Stylix for consistent theming across applications:

- **Theme**: Nord color scheme
- **Fonts**: System-wide font configuration
- **Wallpaper**: Random wallpaper rotation in Hyprland
- **Opacity**: Terminal transparency settings
- **Icons**: Consistent icon themes across applications

## 🔧 Key Features by Module

### CLI Tools (`modules/home-manager/cli/`)
- **Neovim**: Full IDE setup with LSP, completion, and plugins via nixvim
- **Zsh**: Oh-my-zsh with custom aliases and scripts
- **Zellij**: Terminal multiplexer for session management
- **Git**: Configured with aliases and lazygit integration
- **Terminal utilities**: bat, eza, ripgrep, fzf, fd, and more

### Desktop (`modules/home-manager/desktop/`)
- **Hyprland**: Wayland compositor with custom keybinds and animations
- **Waybar**: Status bar with weather, media, and system modules
- **Rofi**: Application launcher with Nord theme
- **Screenshots**: Grim + Slurp + Satty for Wayland
- **Notifications**: SwayNotificationCenter

## 🛠️ Troubleshooting

- **Rebuild fails**: Check syntax with `nix flake check`
- **Previous generation**: Roll back with `sudo nixos-rebuild switch --rollback`
- **Logs**: Check `journalctl -xe` for service errors
- **Hyprland issues**: Logs in `~/.local/share/hyprland/`
