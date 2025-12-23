# Arch Linux Setup Checklist

Use this checklist to set up Nix and home-manager on your Arch Linux system.

## Pre-Installation

- [ ] Arch Linux is installed and running
- [ ] You have internet connectivity
- [ ] You have `curl` and `git` installed
  ```bash
  sudo pacman -S curl git
  ```
- [ ] You're logged in as a regular user (not root)

## Phase 1: Install Nix Package Manager

- [ ] Install Nix in multi-user daemon mode
  ```bash
  sh <(curl -L https://nixos.org/nix/install) --daemon
  ```
- [ ] Restart your shell or source the Nix profile
  ```bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  ```
- [ ] Verify Nix is installed
  ```bash
  nix --version
  ```
- [ ] Enable flakes
  ```bash
  mkdir -p ~/.config/nix
  echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
  ```

## Phase 2: Install System Dependencies

These packages must be installed via pacman (not Nix):

### Required Desktop Environment
- [ ] Install Hyprland
  ```bash
  sudo pacman -S hyprland
  ```
- [ ] Install desktop portals
  ```bash
  sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  ```
- [ ] Install Wayland support
  ```bash
  sudo pacman -S qt5-wayland qt6-wayland
  ```

### Required Audio System
- [ ] Install PipeWire
  ```bash
  sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  ```
- [ ] Enable audio services
  ```bash
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  ```
- [ ] Test audio
  ```bash
  pactl info
  ```

### Required Networking
- [ ] Install NetworkManager (if not already installed)
  ```bash
  sudo pacman -S networkmanager
  ```
- [ ] Enable NetworkManager
  ```bash
  sudo systemctl enable --now NetworkManager
  ```

### Optional but Recommended
- [ ] Install Bluetooth
  ```bash
  sudo pacman -S bluez bluez-utils
  sudo systemctl enable --now bluetooth
  ```
- [ ] Install Polkit
  ```bash
  sudo pacman -S polkit
  ```
- [ ] Install display manager (if you want graphical login)
  ```bash
  sudo pacman -S sddm  # or gdm, ly, etc.
  sudo systemctl enable sddm
  ```

## Phase 3: Clone Configuration

- [ ] Clone this repository
  ```bash
  cd ~
  git clone https://github.com/Odinyg/nixflake.git
  cd nixflake
  ```
- [ ] Switch to the Arch branch
  ```bash
  git checkout copilot/set-up-arch-with-nix
  ```
  Or whatever branch name is being used for Arch support

## Phase 4: Create Your Configuration

- [ ] Copy the example configuration
  ```bash
  cp -r arch-hosts/example arch-hosts/$(hostname)
  ```
- [ ] Update username in your configuration
  ```bash
  sed -i "s/youruser/$USER/g" arch-hosts/$(hostname)/home.nix
  ```
- [ ] Edit configuration to customize modules
  ```bash
  vim arch-hosts/$(hostname)/home.nix
  ```
  - [ ] Verify username is correct
  - [ ] Enable/disable modules as needed
  - [ ] Add any custom packages

## Phase 5: Update Flake Configuration

- [ ] Edit `flake.nix`
- [ ] Add your configuration to `homeConfigurations` section:
  ```nix
  "$USER@$(hostname)" = mkStandaloneHomeConfig {
    username = "$USER";
    stateVersion = "25.05";
    hostname = "$(hostname)";
    extraModules = [ ./arch-hosts/$(hostname)/home.nix ];
  };
  ```
- [ ] Save the file

## Phase 6: Build and Activate

- [ ] Initialize home-manager (first time only)
  ```bash
  nix run home-manager/master -- init
  ```
- [ ] Build your configuration
  ```bash
  nix run home-manager/master -- switch --flake .#$USER@$(hostname)
  ```
- [ ] Wait for build to complete (this may take a while the first time)

## Phase 7: Setup Shell Integration

- [ ] Add Nix to your shell configuration

  **For Bash (~/.bashrc):**
  ```bash
  cat >> ~/.bashrc << 'EOF'

  # Nix
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  # Home-manager
  if [ -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  fi
  EOF
  ```

  **For Zsh (~/.zshrc):**
  ```bash
  cat >> ~/.zshrc << 'EOF'

  # Nix
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  # Home-manager
  if [ -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  fi
  EOF
  ```

- [ ] Restart your shell or source the file
  ```bash
  source ~/.bashrc  # or ~/.zshrc
  ```

## Phase 8: Setup Justfile (Optional but Recommended)

- [ ] Copy Arch justfile
  ```bash
  cp justfile-arch justfile
  ```
- [ ] Verify it works
  ```bash
  just --list
  ```

## Phase 9: Verification

- [ ] Test that home-manager is working
  ```bash
  home-manager generations
  ```
- [ ] Verify Nix packages are in PATH
  ```bash
  which nvim  # Should show a path in /nix/store
  ```
- [ ] Check that dotfiles are linked
  ```bash
  ls -la ~/.config
  ```
- [ ] Test rebuilding
  ```bash
  just rebuild
  ```

## Phase 10: Test Desktop Environment

- [ ] Log out of current session
- [ ] Select Hyprland from display manager (if using one)
- [ ] Log in
- [ ] Verify Hyprland is running
  ```bash
  echo $XDG_CURRENT_DESKTOP  # Should show "Hyprland"
  ```
- [ ] Test waybar appears
- [ ] Test rofi launcher (Super+D)
- [ ] Test terminal (Super+Enter)

## Troubleshooting Checklist

If something doesn't work:

- [ ] Check Nix daemon is running
  ```bash
  sudo systemctl status nix-daemon
  ```
- [ ] Check audio services
  ```bash
  systemctl --user status pipewire
  ```
- [ ] Check Bluetooth (if using)
  ```bash
  sudo systemctl status bluetooth
  ```
- [ ] Check NetworkManager
  ```bash
  sudo systemctl status NetworkManager
  ```
- [ ] Verify flake syntax
  ```bash
  nix flake check
  ```
- [ ] Check home-manager logs
  ```bash
  journalctl --user -u home-manager-*.service
  ```
- [ ] View Hyprland logs
  ```bash
  cat ~/.local/share/hyprland/hyprland.log
  ```

## Post-Installation

- [ ] Commit your configuration changes
  ```bash
  git add arch-hosts/$(hostname)/
  git commit -m "Add $(hostname) configuration"
  ```
- [ ] Set up automatic updates (optional)
  ```bash
  # Add to crontab or create a systemd timer
  # Example: run 'just upgrade' weekly
  ```
- [ ] Install additional Arch packages as needed
  ```bash
  sudo pacman -S ...
  ```
- [ ] Customize your home.nix further
- [ ] Read the documentation:
  - [ ] [ARCH-SETUP.md](./ARCH-SETUP.md) - Detailed guide
  - [ ] [README-ARCH.md](./README-ARCH.md) - Overview
  - [ ] [arch-hosts/README.md](./arch-hosts/README.md) - Configuration guide

## Maintenance Checklist

### Daily/Weekly
- [ ] Update Arch packages: `sudo pacman -Syu`
- [ ] Update Nix packages: `just upgrade`

### Monthly
- [ ] Clean old generations: `just gc`
- [ ] Clean pacman cache: `sudo pacman -Sc`
- [ ] Commit configuration changes: `git commit -am "Update config"`

### When Changing Configuration
- [ ] Edit `arch-hosts/$(hostname)/home.nix`
- [ ] Run `just rebuild`
- [ ] Verify changes work
- [ ] Commit to git

## Success Indicators

You've successfully set up Arch + Nix when:

✅ `nix --version` shows Nix version
✅ `home-manager --version` shows home-manager version
✅ `just rebuild` successfully rebuilds your configuration
✅ Hyprland starts and displays correctly
✅ Audio works in applications
✅ Dotfiles are properly linked from Nix store
✅ Terminal, editor, and other tools launch correctly

## Need Help?

- **Quick Start:** [ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md)
- **Full Guide:** [ARCH-SETUP.md](./ARCH-SETUP.md)
- **Migration Guide:** [NIXOS-TO-ARCH.md](./NIXOS-TO-ARCH.md)
- **Configuration Help:** [arch-hosts/README.md](./arch-hosts/README.md)
- **Arch Wiki:** https://wiki.archlinux.org/
- **Home-manager Manual:** https://nix-community.github.io/home-manager/

## Common Issues and Solutions

### "Nix not found"
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### "home-manager not found"
```bash
nix run home-manager/master -- init
```

### "experimental-features" error
```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "Module not found"
Check that imports use correct path:
```nix
imports = [ ../../profiles/home-manager/base.nix ];
```

### Hyprland won't start
- Verify installed: `pacman -Q hyprland`
- Check logs: `cat ~/.local/share/hyprland/hyprland.log`

### Audio not working
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

---

**Good luck with your Arch + Nix setup! 🚀**
