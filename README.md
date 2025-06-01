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
- **Neovim** with nixvim configuration
- **Zellij** with few changes mostly stock
- **Zsh** with oh-my-zsh
- **Git** with lazygit integration
- **Direnv** for project environments
- **Docker** with rootless configuration

### Applications & Tools
- **Terminal**: Kitty
- **File Manager**: Thunar
- **Browser**: Zen/brave
- **Communication**: Discord (Vesktop), Teams
- **Productivity**: Obsidian, LibreOffice
- **Development**: Various language servers, formatters, and tools

### System Features
- **Stylix** for consistent theming (Nord theme)
- **Home Manager** for user configuration
- **Tailscale** for VP
- **Syncthing** for file synchronization
- **Audio**: PipeWire with PulseAudio compatibility
- **Virtualization**: Docker, QEMU/KVM, VirtualBox, virt-manager

## 🚀 Quick Start

### Prerequisites
- NixOS installed
- Flakes enabled in your Nix configuration

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Odinyg/nixflake/edit/main/README.md 
   cd nixflake
   ```

2. **Build and switch** (replace `<host>` with your target host)
   ```bash
   sudo nixos-rebuild switch --flake .#<host>
   ```

3. **Available commands** (using justfile)
   ```bash
   # Rebuild current host
   just rebuild
   
   # Update flake inputs and rebuild
   just upgrade
   
   # Rebuild into new bootalble instance
   just boot
   
   # Verbose rebuild
   just verbose
   
   # Clean old generations
   just gc
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
- **Fonts**: Configurable with defaults
- **Wallpaper**: Custom wallpaper in hyprland config
- **Opacity**: Terminal transparency settings

## 🔧 Key Features by Module

### CLI Tools (`modules/home-manager/cli/`)
- **Neovim**: Full IDE setup with LSP, completion, and plugins
- **Zsh**: Oh-my-zsh
- **Zellij**: Session management
- **Git**: Aliases and lazygit integration
- **Terminal utilities**: bat, eza, ripgrep, fzf, and more

### Desktop (`modules/home-manager/desktop/`)
- **Hyprland**: Wayland compositor with custom keybinds
- **Waybar**: Status bar with custom modules
- **Rofi**: Application launcher
- **Screenshots**: Grim + Slurp for Wayland
