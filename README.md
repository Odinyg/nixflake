# NixOS Flake Configuration

A modular, reproducible NixOS configuration using flakes with home-manager integration. Supports multiple hosts, desktop environments, and a layered profile system for maximum reusability.

> 🐧 **Using Arch Linux?** Check out the [Arch Linux branch](../../tree/copilot/set-up-arch-with-nix) for standalone home-manager setup!
> - **Quick Start:** [ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md)
> - **Full Guide:** [ARCH-SETUP.md](./ARCH-SETUP.md)
> - **Arch README:** [README-ARCH.md](./README-ARCH.md)

## 🖥️ Hosts

| Host | Description | User | Desktop | Hardware |
|------|-------------|------|---------|----------|
| **VNPC-21** | ThinkPad P53 workstation | odin | Hyprland | Lenovo ThinkPad P53, NVIDIA GPU |
| **laptop** | Portable laptop | none | Hyprland | Generic laptop |
| **station** | Desktop build server | none | Hyprland | AMD desktop, NVIDIA GPU |

## ✨ Key Features

### 🎨 Desktop Environment
- **Hyprland** (primary) - Modern Wayland compositor with custom animations and keybinds
- **BSPWM** (alternative) - X11 tiling window manager
- **COSMIC** (experimental) - System76's new desktop environment
- **Waybar** - Customized status bar with system monitoring
- **Rofi** - Application launcher with Nord theming
- **SwayNC** - Notification daemon for Wayland

### 💻 Development Tools
- **Neovim** - Full IDE via nixvim (LSP, completion, formatting, linting)
- **Zellij** - Terminal multiplexer with persistent sessions
- **Zsh** - Shell with oh-my-zsh, custom aliases, and completions
- **Git** - Configured with lazygit integration
- **Docker** - Container runtime with rootless mode
- **Direnv** - Automatic environment loading per project
- **Language Support** - LSPs and formatters for Nix, Python, Go, Rust, TypeScript, and more

### 🎨 Theming & Styling
- **Stylix** - Unified theming system across all applications
- **Nord** - Primary color scheme
- **Custom fonts** - Nerd Fonts with Japanese and CJK support
- **Dynamic wallpapers** - Random rotation in Hyprland
- **Transparency** - Configurable terminal opacity

### 🔧 System Services
- **Tailscale** - Mesh VPN networking
- **Syncthing** - Peer-to-peer file synchronization
- **SOPS-nix** - Encrypted secrets management
- **PipeWire** - Modern audio server with PulseAudio compatibility
- **Flatpak** - Additional application packaging
- **Printing** - CUPS with Brother printer drivers

### 🎮 Virtualization & Gaming
- **QEMU/KVM** - Virtual machines via virt-manager
- **VirtualBox** - Additional VM support
- **Docker** - Container orchestration
- **Gaming** (station) - Heroic launcher, Bottles, Steam via Flatpak

## 🚀 Quick Start

### Prerequisites
```bash
# Enable flakes in your NixOS configuration
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Odinyg/nixflake.git
   cd nixflake
   ```

2. **Build and switch to your host**
   ```bash
   # Using justfile (recommended)
   just rebuild

   # Or manually
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

3. **Available just commands**
   ```bash
   just rebuild    # Rebuild current host (auto-detects)
   just upgrade    # Update flake inputs + rebuild
   just boot       # Build new boot configuration
   just verbose    # Rebuild with detailed output
   just gc         # Clean generations older than 14 days
   just diff       # View git changes (excludes flake.lock)
   ```

## 📁 Repository Structure

```
.
├── flake.nix                   # Main flake entry point
├── flake.lock                  # Pinned dependency versions
├── justfile                    # Build automation commands
├── CLAUDE.md                   # AI assistant instructions
│
├── hosts/                      # Host-specific configurations
│   ├── vnpc-21/               # ThinkPad P53 workstation
│   ├── laptop/                # Generic laptop
│   └── station/               # Desktop build server
│
├── profiles/                   # Layered configuration profiles
│   ├── base.nix               # Minimal base system
│   ├── laptop.nix             # Laptop-specific settings (extends base)
│   ├── desktop.nix            # Desktop hardware (extends base)
│   └── workstation.nix        # Full workstation (extends desktop)
│
├── modules/
│   ├── nixos/                 # System-level modules
│   │   ├── hardware/          # GPU, audio, bluetooth, networking
│   │   ├── services/          # System services
│   │   ├── general.nix        # Core system packages
│   │   ├── fonts.nix          # Font configuration
│   │   └── secrets.nix        # SOPS secrets management
│   │
│   └── home-manager/          # User-level modules
│       ├── app/               # GUI applications
│       ├── cli/               # Terminal tools (neovim, zsh, git)
│       ├── desktop/           # Desktop environments
│       │   ├── hyprland/      # Hyprland configuration
│       │   ├── bspwm/         # BSPWM configuration
│       │   └── cosmic/        # COSMIC desktop
│       └── misc/              # Miscellaneous configs
│
└── secrets/                    # Encrypted secrets (SOPS)
    ├── secrets.yaml
    └── general.yaml
```

## 🏗️ Architecture

### Profile System
Configurations are layered for maximum reusability:

```
base.nix (core system)
  ├─→ laptop.nix (base + laptop hardware)
  └─→ desktop.nix (base + desktop hardware)
       └─→ workstation.nix (desktop + dev tools)
```

Each host imports a profile and adds host-specific overrides.

### Module Pattern
All optional features use the enable pattern:

```nix
# In host configuration
moduleName.enable = true;
```

This makes it easy to mix and match features per host.

## ⚙️ Configuration

### Adding a New Host

1. **Generate hardware configuration**
   ```bash
   nixos-generate-config --show-hardware-config > hosts/newhost/hardware-configuration.nix
   ```

2. **Create host configuration**
   ```nix
   # hosts/newhost/default.nix
   { config, pkgs, lib, inputs, ... }: {
     imports = [
       ./hardware-configuration.nix
       ../../profiles/laptop.nix  # Choose appropriate profile
     ];

     # Networking
     networking.hostName = "newhost";

     # User configuration
     users.users.myuser = {
       isNormalUser = true;
       extraGroups = [ "networkmanager" "wheel" ];
       shell = pkgs.zsh;
     };

     # Enable desired features
     hyprland.enable = true;
     neovim.enable = true;

     system.stateVersion = "25.05";
   }
   ```

3. **Add to flake.nix**
   ```nix
   nixosConfigurations.newhost = nixpkgs.lib.nixosSystem {
     specialArgs = { inherit inputs; };
     modules = commonModules ++ [
       ./hosts/newhost
       { user = "myuser"; }
       {
         nixpkgs.config.allowUnfree = true;
         home-manager = {
           useGlobalPkgs = true;
           useUserPackages = true;
           extraSpecialArgs = { inherit inputs; };
           users.myuser = mkHomeConfig {
             username = "myuser";
             stateVersion = "25.05";
           };
         };
       }
     ];
   };
   ```

4. **Build and test**
   ```bash
   nix flake check
   sudo nixos-rebuild switch --flake .#newhost
   ```

### Enabling/Disabling Features

Most modules use boolean enable options:

```nix
# Desktop environments
hyprland.enable = true;
bspwm.enable = false;

# Applications
discord.enable = true;
firefox.enable = false;

# System features
secrets.enable = true;
gaming.enable = true;
```

### Customizing Per Host

Host-specific overrides go in `hosts/<hostname>/default.nix`:

```nix
# Override terminal opacity
styling.opacity.terminal = 0.85;

# Enable specific services
init-net.enable = true;
hosted-services.n8n.enable = true;

# Add extra packages
users.users.odin.packages = with pkgs; [
  custom-package
];
```

## 🔐 Secrets Management

This configuration uses SOPS-nix for encrypted secrets:

```bash
# Initialize age key for new host
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Edit secrets
sops secrets/secrets.yaml
```

Secrets are automatically decrypted at boot and placed in `/run/secrets/`.

## 🎨 Theming

Theming is managed by Stylix with the Nord color scheme. To customize:

```nix
# In host configuration
stylix = {
  base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  image = ./wallpaper.png;

  fonts = {
    monospace = {
      package = pkgs.nerdfonts;
      name = "JetBrainsMono Nerd Font";
    };
  };
};
```

## 🛠️ Troubleshooting

### Common Issues

**Build fails with syntax error**
```bash
nix flake check  # Validate flake syntax
```

**Need to rollback to previous generation**
```bash
sudo nixos-rebuild switch --rollback
```

**Checking system logs**
```bash
journalctl -xe              # System logs
journalctl -u SERVICE       # Specific service
```

**Hyprland issues**
```bash
# Check Hyprland logs
cat ~/.local/share/hyprland/hyprland.log

# Restart Hyprland
hyprctl reload
```

**Home Manager issues**
```bash
# Rebuild just home-manager
home-manager switch --flake .#<user>@<host>
```

### Cleaning Up

```bash
# Remove old generations
sudo nix-collect-garbage -d

# Remove old boot entries
sudo /run/current-system/bin/switch-to-configuration boot

# Optimize nix store
nix-store --optimize
```

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes Wiki](https://nixos.wiki/wiki/Flakes)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Stylix Documentation](https://github.com/danth/stylix)
