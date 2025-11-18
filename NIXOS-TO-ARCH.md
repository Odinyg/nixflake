# Migrating from NixOS to Arch Linux (with Nix)

This guide is for users who want to move from NixOS to Arch Linux while keeping their Nix-managed user environment.

## Why Migrate?

**Reasons to use Arch + Nix instead of pure NixOS:**
- Access to AUR (Arch User Repository)
- Faster package updates for system components
- More hardware compatibility (bleeding-edge kernel)
- Simpler system administration
- Mix Arch packages with Nix packages
- Better gaming support (easier graphics drivers)

**What you'll keep:**
- All your dotfiles and user configurations
- Declarative home environment
- Nix package management for user packages
- Reproducible user environment

**What changes:**
- System configuration moves to traditional Arch tools
- Boot loader managed by Arch (GRUB/systemd-boot)
- System services use Arch's systemd units
- Kernel and hardware managed by pacman

## Migration Steps

### Phase 1: Prepare on NixOS

1. **Backup your data**
   - Important files
   - Home directory
   - NixOS configuration

2. **Document your system**
   ```bash
   # List all installed packages
   nix-env -q > ~/nixos-packages.txt
   
   # List enabled services
   systemctl list-unit-files --state=enabled > ~/nixos-services.txt
   
   # Save your configuration
   cd ~/nixflake  # or wherever your config is
   git status
   git commit -am "Final NixOS configuration"
   git push
   ```

3. **Note your hardware**
   - Graphics card (NVIDIA/AMD/Intel)
   - Audio setup
   - Network card
   - Special hardware requirements

### Phase 2: Install Arch Linux

Follow the [Arch Installation Guide](https://wiki.archlinux.org/title/Installation_guide):

1. **Boot Arch ISO**
2. **Partition disks** (use same layout as NixOS if possible)
3. **Install base system**
   ```bash
   pacstrap /mnt base linux linux-firmware
   ```
4. **Configure basic system**
   ```bash
   # Generate fstab
   genfstab -U /mnt >> /mnt/etc/fstab
   
   # Chroot and configure
   arch-chroot /mnt
   
   # Set timezone
   ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
   hwclock --systohc
   
   # Set locale
   echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
   
   # Set hostname
   echo "yourhostname" > /etc/hostname
   
   # Set root password
   passwd
   ```

5. **Install boot loader**
   ```bash
   # For systemd-boot (UEFI)
   bootctl install
   
   # Create boot entry
   cat > /boot/loader/entries/arch.conf << EOF
   title Arch Linux
   linux /vmlinuz-linux
   initrd /initramfs-linux.img
   options root=UUID=$(blkid -s UUID -o value /dev/sdXn) rw
   EOF
   
   # Or use GRUB if preferred
   pacman -S grub efibootmgr
   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   ```

6. **Install essential packages**
   ```bash
   pacman -S base-devel networkmanager sudo vim git
   ```

7. **Create user**
   ```bash
   useradd -m -G wheel -s /bin/bash yourusername
   passwd yourusername
   
   # Enable sudo for wheel group
   EDITOR=vim visudo
   # Uncomment: %wheel ALL=(ALL:ALL) ALL
   ```

8. **Reboot into Arch**

### Phase 3: Setup Hardware and Desktop

1. **Enable NetworkManager**
   ```bash
   sudo systemctl enable --now NetworkManager
   ```

2. **Install graphics drivers**
   
   **For NVIDIA:**
   ```bash
   sudo pacman -S nvidia nvidia-utils
   ```
   
   **For AMD:**
   ```bash
   sudo pacman -S mesa vulkan-radeon libva-mesa-driver
   ```
   
   **For Intel:**
   ```bash
   sudo pacman -S mesa vulkan-intel intel-media-driver
   ```

3. **Install audio system**
   ```bash
   sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
   systemctl --user enable --now pipewire pipewire-pulse wireplumber
   ```

4. **Install Bluetooth**
   ```bash
   sudo pacman -S bluez bluez-utils
   sudo systemctl enable --now bluetooth
   ```

5. **Install Hyprland and dependencies**
   ```bash
   sudo pacman -S hyprland \
     xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
     qt5-wayland qt6-wayland \
     polkit
   ```

6. **Install display manager (optional)**
   ```bash
   # Choose one:
   sudo pacman -S sddm  # Qt-based
   # or
   sudo pacman -S gdm   # GNOME
   # or
   sudo pacman -S ly    # TUI
   
   sudo systemctl enable sddm  # or gdm/ly
   ```

### Phase 4: Setup Nix and Home-Manager

1. **Install Nix**
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
   ```

2. **Enable flakes**
   ```bash
   mkdir -p ~/.config/nix
   cat > ~/.config/nix/nix.conf << EOF
   experimental-features = nix-command flakes
   EOF
   ```

3. **Clone your NixFlake repository**
   ```bash
   cd ~
   git clone https://github.com/yourusername/nixflake.git
   cd nixflake
   git checkout copilot/set-up-arch-with-nix  # or appropriate branch
   ```

4. **Create Arch configuration**
   ```bash
   # Copy and customize
   cp -r arch-hosts/example arch-hosts/$(hostname)
   
   # Edit the configuration
   sed -i "s/youruser/$USER/g" arch-hosts/$(hostname)/home.nix
   
   # Customize modules as needed
   vim arch-hosts/$(hostname)/home.nix
   ```

5. **Update flake.nix**
   
   Add your configuration to the `homeConfigurations` section:
   ```nix
   "$USER@$(hostname)" = mkStandaloneHomeConfig {
     username = "$USER";
     stateVersion = "25.05";
     hostname = "$(hostname)";
     extraModules = [ ./arch-hosts/$(hostname)/home.nix ];
   };
   ```

6. **Build and activate**
   ```bash
   nix run home-manager/master -- switch --flake .#$USER@$(hostname)
   
   # Setup justfile
   cp justfile-arch justfile
   ```

### Phase 5: Configure Shell

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Nix
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Home-manager
if [ -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
  . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
fi
```

### Phase 6: Restore Your Environment

1. **Apply your home-manager configuration**
   ```bash
   just rebuild  # or home-manager switch --flake .#...
   ```

2. **Verify services are running**
   ```bash
   # Audio
   systemctl --user status pipewire
   
   # Bluetooth
   sudo systemctl status bluetooth
   
   # Network
   nmcli device status
   ```

3. **Test Hyprland**
   ```bash
   # Log out and log in with Hyprland
   # Or test directly:
   Hyprland
   ```

## Configuration Differences

### System Services

**NixOS:**
```nix
services.pipewire.enable = true;
services.bluetooth.enable = true;
```

**Arch:**
```bash
sudo pacman -S pipewire bluez
sudo systemctl enable --now pipewire bluetooth
```

### System Packages

**NixOS:**
```nix
environment.systemPackages = with pkgs; [
  firefox
  git
];
```

**Arch:**
```bash
# System-wide packages via pacman
sudo pacman -S firefox git

# Or user packages via Nix home-manager
home.packages = with pkgs; [ firefox git ];
```

### Boot Configuration

**NixOS:**
```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

**Arch:**
```bash
# Edit /boot/loader/loader.conf
# Or use GRUB configuration
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Users

**NixOS:**
```nix
users.users.myuser = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
};
```

**Arch:**
```bash
sudo useradd -m -G wheel,networkmanager myuser
sudo passwd myuser
```

## Module Availability

### ✅ Available on Arch (via home-manager)

- All CLI tools (neovim, zsh, git, etc.)
- Desktop environment configs (Hyprland, waybar, rofi)
- User applications
- Development tools
- Theming (Stylix)
- Dotfiles

### ❌ Not Available (NixOS-specific)

- System services (`services.*`)
- Boot configuration (`boot.*`)
- Hardware configuration (`hardware.*`)
- System users (`users.users.*`)
- Kernel modules
- System-wide packages

## Troubleshooting

### Graphics Issues

**NVIDIA:**
```bash
# Install proper drivers
sudo pacman -S nvidia nvidia-utils

# Add to kernel parameters if needed
# Edit /etc/default/grub and add: nvidia-drm.modeset=1
```

### Audio Not Working

```bash
# Check PipeWire
systemctl --user status pipewire

# Restart if needed
systemctl --user restart pipewire pipewire-pulse
```

### Hyprland Won't Start

```bash
# Check logs
cat ~/.local/share/hyprland/hyprland.log

# Verify installation
which Hyprland
pacman -Q hyprland
```

### Home-manager Issues

```bash
# Check build
nix flake check

# Rebuild with verbose
home-manager switch --flake .#$USER@$(hostname) --verbose
```

## Best Practices

1. **Use Arch for system packages:**
   - Kernel
   - Graphics drivers
   - System services
   - Hardware support

2. **Use Nix for user packages:**
   - Development tools
   - CLI utilities
   - Desktop applications
   - Dotfiles management

3. **Keep both updated:**
   ```bash
   # Update Arch
   sudo pacman -Syu
   
   # Update Nix packages
   just upgrade
   ```

4. **Backup regularly:**
   - Your home-manager configuration (git commit/push)
   - Important files
   - Pacman package list: `pacman -Qqe > pkglist.txt`

## Performance Considerations

**Pros of Arch + Nix:**
- Faster boot times (less to build)
- Quicker system updates
- More efficient use of disk space
- Better performance for gaming

**Cons:**
- Two package managers to maintain
- System not fully declarative
- Manual service configuration

## Getting Help

- **Arch Wiki:** https://wiki.archlinux.org/
- **Home-manager Manual:** https://nix-community.github.io/home-manager/
- **This repo's documentation:**
  - [ARCH-SETUP.md](./ARCH-SETUP.md)
  - [ARCH-QUICKSTART.md](./ARCH-QUICKSTART.md)
  - [README-ARCH.md](./README-ARCH.md)

## Conclusion

You now have:
- ✅ Arch Linux base system
- ✅ Nix package manager for user environment
- ✅ Your familiar dotfiles and configurations
- ✅ Best of both worlds

Welcome to Arch + Nix! 🎉
