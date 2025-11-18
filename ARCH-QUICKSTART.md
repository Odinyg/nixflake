# Arch Linux Quick Start

**TL;DR:** Get up and running with Nix and home-manager on Arch Linux in 5 steps.

## Prerequisites
- Arch Linux installed
- Internet connection

## Installation (Copy-Paste Ready)

### Step 1: Install Nix
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Step 2: Enable Flakes
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

### Step 3: Install System Dependencies
```bash
sudo pacman -S --needed \
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  pipewire pipewire-pulse wireplumber \
  bluez bluez-utils networkmanager \
  polkit qt5-wayland qt6-wayland
```

### Step 4: Enable Services
```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now bluetooth NetworkManager
```

### Step 5: Clone and Setup
```bash
git clone https://github.com/Odinyg/nixflake.git ~/nixflake
cd ~/nixflake
git checkout copilot/set-up-arch-with-nix  # or whatever branch name

# Create your configuration
cp -r arch-hosts/example arch-hosts/$(hostname)
sed -i "s/youruser/$USER/g" arch-hosts/$(hostname)/home.nix
```

### Step 6: Edit flake.nix
Add your configuration to `flake.nix` in the `homeConfigurations` section:

```nix
"$USER@$(hostname)" = mkStandaloneHomeConfig {
  username = "$USER";
  stateVersion = "25.05";
  hostname = "$(hostname)";
  extraModules = [ ./arch-hosts/$(hostname)/home.nix ];
};
```

Or use this one-liner to add it (careful with quoting):
```bash
# This is a template - adjust as needed
YOUR_USERNAME="$USER"
YOUR_HOSTNAME="$(hostname)"

# Add your config to flake.nix after the example config
# (Manually edit the file - automated editing of Nix is risky)
```

### Step 7: Build and Activate
```bash
# First time setup
nix run home-manager/master -- switch --flake .#$USER@$(hostname)

# Setup justfile for future use
cp justfile-arch justfile

# Future rebuilds
just rebuild
```

## Daily Usage

```bash
# Rebuild configuration
just rebuild

# Update packages
just upgrade

# Clean old generations
just gc

# List all commands
just --list
```

## What You Get

✅ **Managed by Nix:**
- Neovim with full IDE setup
- Zsh with oh-my-zsh
- Git, direnv, language servers
- Hyprland configuration
- Desktop apps (Discord, Chromium, etc.)
- Consistent theming (Nord)

🔧 **Managed by Arch:**
- Hyprland package itself
- System services (NetworkManager, Bluetooth, PipeWire)
- Kernel and drivers
- Boot loader

## Customization

Edit `arch-hosts/$(hostname)/home.nix` to enable/disable modules:

```nix
{
  # Enable what you want
  hyprland.enable = true;
  neovim.enable = true;
  discord.enable = true;
  
  # Disable what you don't
  chromium.enable = false;
  
  # Add extra packages
  home.packages = with pkgs; [
    htop
    ripgrep
  ];
}
```

Then run: `just rebuild`

## Troubleshooting

**Nix not found after install:**
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

**Home-manager not found:**
```bash
nix run home-manager/master -- init
```

**Flake errors:**
```bash
nix flake check
```

**Rollback to previous generation:**
```bash
home-manager generations
home-manager switch --flake .#$USER@$(hostname) --rollback
```

## More Information

- **Full Setup Guide:** [ARCH-SETUP.md](./ARCH-SETUP.md)
- **Arch README:** [README-ARCH.md](./README-ARCH.md)
- **Original NixOS README:** [README.md](./README.md)

## Support

This is a standalone branch for Arch Linux support. The main branch is for NixOS.

Branch: `copilot/set-up-arch-with-nix` (or `arch`)

---

**Enjoy declarative dotfiles on Arch! 🚀**
