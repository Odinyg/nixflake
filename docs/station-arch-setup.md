# Station — Arch Linux Installation & Base System Setup Guide

This guide covers a complete manual Arch Linux installation tailored to the **station** hardware:
AMD CPU + NVIDIA GPU, NVMe SSD (`/dev/nvme0n1`), static IP `10.10.10.10/24` on `enp82s0`.

> **Note:** This is a documentation-only guide. No automation scripts. Manual steps only.

---

## Section 1: Prerequisites

### 1.1 Download Arch Linux ISO

Download the latest ISO from [archlinux.org/download](https://archlinux.org/download/).

### 1.2 Create Bootable USB

```bash
dd bs=4M if=archlinux-*.iso of=/dev/sdX conv=fsync oflag=direct status=progress
```

Replace `/dev/sdX` with your USB device (check with `lsblk`).

### 1.3 Boot from USB

- Enter BIOS/UEFI firmware (usually `Del` or `F2` on boot)
- Ensure **UEFI mode** is enabled (not legacy/CSM)
- Set USB as first boot device
- Disable Secure Boot

### Verification

```bash
# After booting the live environment, confirm UEFI mode:
ls /sys/firmware/efi/efivars
# Should list files — if empty or missing, you booted in BIOS mode
```

---

## Section 2: Disk Partitioning

### 2.1 Identify the Target Device

```bash
lsblk
# Confirm /dev/nvme0n1 is the NVMe SSD
fdisk -l /dev/nvme0n1
```

### 2.2 Partition the Disk

Recommended layout for station (UEFI + ext4):

| Partition       | Size    | Type             | Mount  |
|-----------------|---------|------------------|--------|
| `/dev/nvme0n1p1` | 1 GiB  | EFI System       | `/boot/efi` |
| `/dev/nvme0n1p2` | 16 GiB | Linux swap       | `[SWAP]` |
| `/dev/nvme0n1p3` | Rest   | Linux filesystem | `/`    |

```bash
fdisk /dev/nvme0n1
```

Inside `fdisk`:
```
g          # Create new GPT partition table
n          # New partition (p1 — EFI)
  <enter>  # Default partition number (1)
  <enter>  # Default first sector
  +1G      # 1 GiB size
t          # Change type
  1        # EFI System (type 1)

n          # New partition (p2 — swap)
  <enter>  # Default partition number (2)
  <enter>  # Default first sector
  +16G     # 16 GiB swap
t          # Change type
  2        # Select partition 2
  19       # Linux swap (type 19)

n          # New partition (p3 — root)
  <enter>  # Default partition number (3)
  <enter>  # Default first sector
  <enter>  # Use remaining space

w          # Write and exit
```

### 2.3 Format Partitions

```bash
# EFI partition
mkfs.fat -F32 /dev/nvme0n1p1

# Swap
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2

# Root filesystem (ext4 — proven stable)
mkfs.ext4 /dev/nvme0n1p3
```

### 2.4 Mount Filesystems

```bash
mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
```

### Verification

```bash
lsblk -f /dev/nvme0n1
# Should show: nvme0n1p1 vfat, nvme0n1p2 swap, nvme0n1p3 ext4
free -h
# Should show swap active
```

---

## Section 3: Base Install

### 3.1 Install Base System

> **Important:** Use `linux-lts` kernel — NVIDIA dkms is significantly more stable with LTS.
> Mainline Arch kernel updates frequently break `nvidia-dkms`.

```bash
pacstrap -K /mnt \
  base \
  base-devel \
  linux-lts \
  linux-lts-headers \
  linux-firmware \
  nvidia-dkms \
  nvidia-utils \
  nvidia-settings \
  grub \
  efibootmgr \
  os-prober \
  networkmanager \
  git \
  vim \
  sudo \
  zsh \
  curl \
  wget \
  man-db \
  man-pages
```

### 3.2 Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
# Verify all three partitions are listed with correct UUIDs
```

### 3.3 Chroot into New System

```bash
arch-chroot /mnt
```

### Verification

```bash
# Inside chroot:
uname -r
# Should show the LTS kernel version (e.g., 6.6.x-lts)
pacman -Q linux-lts nvidia-dkms
# Both should be installed
```

---

## Section 4: System Configuration

### 4.1 Locale

```bash
# Edit locale.gen and uncomment en_US.UTF-8
vim /etc/locale.gen
# Uncomment: en_US.UTF-8 UTF-8

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### 4.2 Timezone

```bash
# Set to your actual timezone (adjust if not Oslo)
ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
hwclock --systohc
```

### 4.3 Hostname

```bash
echo "station" > /etc/hostname
```

### 4.4 /etc/hosts

```bash
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   station.localdomain station
EOF
```

### 4.5 Root Password

```bash
passwd
# Enter a strong root password
```

### 4.6 GRUB Bootloader

```bash
# Install GRUB for UEFI
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# Enable os-prober for dual-boot detection
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

# Add NVIDIA kernel parameters (required for Wayland/Hyprland)
# Edit /etc/default/grub and update GRUB_CMDLINE_LINUX_DEFAULT:
vim /etc/default/grub
# Set: GRUB_CMDLINE_LINUX_DEFAULT="quiet nvidia-drm.modeset=1 nvidia_drm.fbdev=1"

# Generate GRUB config
grub-mkconfig -o /boot/grub/grub.cfg
```

### Verification

```bash
ls /boot/efi/EFI/GRUB/
# Should contain grubx64.efi
cat /etc/default/grub | grep CMDLINE
# Should show nvidia-drm.modeset=1
```

---

## Section 5: NVIDIA Setup

### 5.1 Configure mkinitcpio

NVIDIA modules must be loaded early for Wayland/Hyprland to work correctly.

```bash
vim /etc/mkinitcpio.conf
```

Find the `MODULES=()` line and update it:
```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

Also ensure the `HOOKS` line does **not** include `kms` (conflicts with NVIDIA early KMS):
```
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
```

### 5.2 Rebuild initramfs

```bash
mkinitcpio -P
# Should complete without errors for linux-lts
```

### 5.3 Disable NVIDIA Power Management (station is always-on)

```bash
# Create systemd override to disable NVIDIA suspend services
systemctl mask nvidia-suspend.service
systemctl mask nvidia-hibernate.service
systemctl mask nvidia-resume.service
```

### 5.4 Environment Variables for NVIDIA + Wayland

Add to `/etc/environment`:

```bash
cat >> /etc/environment << 'EOF'
GBM_BACKEND=nvidia-drm
WLR_NO_HARDWARE_CURSORS=1
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NIXOS_OZONE_WL=1
EOF
```

### Verification

```bash
# After first boot (not in chroot):
nvidia-smi
# Should show GPU info
lsmod | grep nvidia
# Should show: nvidia, nvidia_modeset, nvidia_uvm, nvidia_drm
```

---

## Section 6: User Setup

### 6.1 Create User `none`

```bash
useradd -m -G wheel,plugdev,dialout,video -s /bin/zsh none
passwd none
# Enter user password
```

> **Note:** `docker` and `libvirt` groups are added later when those services are installed.

### 6.2 Enable sudo for wheel Group

```bash
EDITOR=vim visudo
# Uncomment the line:
# %wheel ALL=(ALL:ALL) ALL
```

### 6.3 Verify zsh is Available

```bash
which zsh
# Should output /bin/zsh
chsh -s /bin/zsh none
```

### Verification

```bash
su - none
whoami
# Should output: none
groups
# Should include: wheel plugdev dialout video
echo $SHELL
# Should output: /bin/zsh
exit
```

---

## Section 7: Networking — Static IP

Station uses a static IP on the Servers VLAN (10.10.10.0/24, VLAN 5) via `enp82s0`.

### 7.1 Enable systemd-networkd

```bash
systemctl enable systemd-networkd
systemctl enable systemd-resolved
```

### 7.2 Create Network Configuration

```bash
cat > /etc/systemd/network/20-wired.network << 'EOF'
[Match]
Name=enp82s0

[Network]
Address=10.10.10.10/24
Gateway=10.10.10.1
DNS=10.10.10.1
DNS=1.1.1.1
EOF
```

### 7.3 Configure DNS Resolution

```bash
# Use systemd-resolved stub resolver
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### 7.4 Disable NetworkManager Conflict (optional)

If NetworkManager is also installed, prevent it from managing `enp82s0`:

```bash
cat > /etc/NetworkManager/conf.d/unmanaged.conf << 'EOF'
[keyfile]
unmanaged-devices=interface-name:enp82s0
EOF
```

### Verification

```bash
# After first boot:
ip addr show enp82s0
# Should show: inet 10.10.10.10/24
ip route
# Should show: default via 10.10.10.1 dev enp82s0
ping -c 3 10.10.10.1
# Should succeed
```

---

## Section 8: Hyprland + Display Manager

### 8.1 Install Hyprland and Dependencies

```bash
pacman -S \
  hyprland \
  greetd \
  greetd-tuigreet \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  xdg-utils \
  qt5-wayland \
  qt6-wayland \
  polkit \
  polkit-gnome \
  waybar \
  dunst \
  rofi-wayland \
  kitty \
  grim \
  slurp \
  wl-clipboard
```

### 8.2 Create Hyprland Session File

```bash
mkdir -p /usr/share/wayland-sessions

cat > /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=A dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
```

### 8.3 Configure greetd

```bash
mkdir -p /etc/greetd

cat > /etc/greetd/config.toml << 'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "greeter"
EOF
```

### 8.4 Enable greetd

```bash
systemctl enable greetd
```

### 8.5 Create Minimal Hyprland Config (for first boot)

```bash
mkdir -p /home/none/.config/hypr

cat > /home/none/.config/hypr/hyprland.conf << 'EOF'
# Minimal config for first boot — will be replaced by home-manager
monitor = HDMI-A-1, 3840x2160@60, 1920x0, 1
monitor = DP-1, 1920x1080@120, 0x0, 1

exec-once = polkit-gnome-authentication-agent-1

input {
    kb_layout = us
    follow_mouse = 1
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
}

# Basic keybinds
$mod = SUPER
bind = $mod, Return, exec, kitty
bind = $mod, Q, killactive
bind = $mod SHIFT, E, exit
EOF

chown -R none:none /home/none/.config
```

### Verification

```bash
# After first boot:
systemctl status greetd
# Should be active/running
ls /usr/share/wayland-sessions/
# Should list hyprland.desktop
```

---

## Section 9: Nix Installation

### 9.1 Install Nix (Multi-User Daemon Mode)

```bash
# Run as root or with sudo
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Follow the prompts. This installs Nix as a multi-user installation with a daemon.

### 9.2 Enable Flakes and Configure Trusted Users

```bash
mkdir -p /etc/nix

cat > /etc/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
trusted-users = root none
max-jobs = auto
cores = 0
EOF
```

### 9.3 Restart Nix Daemon

```bash
systemctl restart nix-daemon
```

### 9.4 Verify Nix Installation

```bash
# Source nix profile (or open a new shell)
source /etc/profile.d/nix.sh

nix --version
# Should output: nix (Nix) 2.x.x

nix flake show nixpkgs
# Should list nixpkgs outputs (may take a moment to download)
```

### Verification

```bash
systemctl status nix-daemon
# Should be active/running
nix-env --version
# Should output version info
```

---

## Section 10: Home Manager Standalone

### 10.1 Clone the Flake Repository

```bash
# As user none:
su - none
git clone https://github.com/Odinyg/nixflake.git ~/nixflake
cd ~/nixflake
```

### 10.2 Set Up SOPS Age Key (Required for Secrets)

```bash
mkdir -p ~/.config/sops/age
# Copy your age private key to:
# ~/.config/sops/age/keys.txt
# (Transfer from another machine or generate a new one)
chmod 600 ~/.config/sops/age/keys.txt
```

### 10.3 Run Home Manager Switch

```bash
# First run (uses nix run — slower but no binary needed):
nix run home-manager/release-25.05 -- switch --flake ~/nixflake#none@station

# Subsequent runs (after home-manager is in PATH):
home-manager switch --flake ~/nixflake#none@station
```

> **Note:** The `none@station` target uses the standalone `homeConfigurations` output
> defined in `parts/home-manager-standalone.nix`. This is separate from the NixOS
> `nixosConfigurations.station` target.

### 10.4 Install home-manager Binary for Faster Runs

```bash
nix profile install nixpkgs#home-manager
# Or via home-manager channel:
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

### Verification

```bash
home-manager --version
# Should output version
ls ~/.nix-profile/bin/ | head -20
# Should list many programs managed by home-manager
```

---

## Section 11: Essential System Packages

### 11.1 Audio (PipeWire)

```bash
pacman -S \
  pipewire \
  pipewire-alsa \
  pipewire-pulse \
  pipewire-jack \
  wireplumber \
  pavucontrol

systemctl --user enable pipewire pipewire-pulse wireplumber
```

### 11.2 Bluetooth

```bash
pacman -S bluez bluez-utils

systemctl enable bluetooth
```

### 11.3 Printing

```bash
pacman -S cups avahi nss-mdns

systemctl enable cups avahi-daemon
```

Edit `/etc/nsswitch.conf` — add `mdns_minimal` to the `hosts:` line:
```
hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns
```

### 11.4 Fonts

```bash
pacman -S \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  ttf-liberation \
  ttf-dejavu
```

### 11.5 AUR Helper (paru)

```bash
# As user none (not root):
su - none
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
makepkg -si
```

### 11.6 Docker

```bash
pacman -S docker docker-compose

systemctl enable docker

# Add none to docker group
usermod -aG docker none
```

### 11.7 Virtualization (libvirt/KVM)

```bash
pacman -S qemu-full libvirt virt-manager dnsmasq

systemctl enable libvirtd

# Add none to libvirt group
usermod -aG libvirt none
```

### Verification

```bash
systemctl status pipewire
# Should be active (run as user)
docker run --rm hello-world
# Should pull and run successfully
```

---

## Section 12: Sleep/Suspend Prevention

Station is an always-on build server — sleep and suspend must be fully disabled.

### 12.1 Mask Sleep Targets

```bash
systemctl mask sleep.target
systemctl mask suspend.target
systemctl mask hibernate.target
systemctl mask hybrid-sleep.target
```

### 12.2 Configure logind

```bash
cat >> /etc/systemd/logind.conf << 'EOF'
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore
IdleAction=ignore
EOF

systemctl restart systemd-logind
```

### 12.3 Configure systemd-sleep

```bash
cat > /etc/systemd/sleep.conf << 'EOF'
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF
```

### Verification

```bash
systemctl status sleep.target
# Should show: masked
systemctl status suspend.target
# Should show: masked
```

---

## Section 13: Environment Variables

### 13.1 System-Wide Variables

Add to `/etc/environment`:

```bash
cat >> /etc/environment << 'EOF'
# Locale archive (needed for Nix-installed programs)
LOCALE_ARCHIVE=/usr/lib/locale/locale-archive

# XDG data dirs — include Nix profile paths
XDG_DATA_DIRS=/home/none/.nix-profile/share:/usr/local/share:/usr/share

# NVIDIA + Wayland
GBM_BACKEND=nvidia-drm
WLR_NO_HARDWARE_CURSORS=1
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NIXOS_OZONE_WL=1
EOF
```

### 13.2 User Shell Environment

Add to `/home/none/.zshenv`:

```bash
cat >> /home/none/.zshenv << 'EOF'
# PATH ordering: system binaries BEFORE Nix profile
# This ensures Hyprland, NVIDIA utils, etc. use pacman versions
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:$PATH"

# Nix
export NIX_PATH="nixpkgs=flake:nixpkgs"
EOF
```

> **Critical:** System binaries (`/usr/bin`) must come **before** `~/.nix-profile/bin` in PATH.
> Hyprland and NVIDIA utilities installed via pacman must take precedence over any Nix-installed
> versions to avoid GPU/Wayland compatibility issues.

### 13.3 Wayland Session Variables

Add to `/etc/profile.d/wayland.sh`:

```bash
cat > /etc/profile.d/wayland.sh << 'EOF'
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export MOZ_ENABLE_WAYLAND=1
    export QT_QPA_PLATFORM=wayland
    export SDL_VIDEODRIVER=wayland
    export CLUTTER_BACKEND=wayland
fi
EOF
```

### Verification

```bash
# After logging in as none:
echo $PATH
# Should show /usr/bin before ~/.nix-profile/bin
echo $GBM_BACKEND
# Should output: nvidia-drm
which hyprland
# Should output: /usr/bin/hyprland (not a nix path)
```

---

## Section 14: nixGL (GPU Apps via Nix)

Some Nix-installed GUI applications require `nixGL` to access the host GPU on non-NixOS systems.

### 14.1 Why nixGL is Needed

On NixOS, the GPU driver paths are baked into the system. On Arch Linux with Nix installed,
Nix-packaged apps that link against OpenGL/Vulkan libraries cannot find the host NVIDIA drivers.
`nixGL` wraps these apps with the correct library paths.

### 14.2 Install nixGL

```bash
# As user none:
nix profile install github:nix-community/nixGL
```

Or add to your home-manager configuration (preferred for reproducibility):

```nix
# In home.nix or equivalent:
home.packages = [
  inputs.nixgl.packages.${pkgs.system}.nixGLDefault
];
```

### 14.3 Usage

```bash
# Wrap any Nix-installed GPU-dependent app:
nixGL kitty
nixGL chromium
nixGL mpv video.mkv

# For apps that need Vulkan:
nixVulkan gameName
```

### 14.4 Alias Convenience (optional)

Add to `~/.zshrc` or home-manager shell aliases:

```bash
alias kitty="nixGL kitty"
alias chromium="nixGL chromium"
```

### 14.5 Alternative: Install GPU Apps via pacman/AUR

To avoid nixGL entirely, install GPU-dependent applications via pacman or AUR instead of Nix:

```bash
# These are better installed via pacman on Arch:
pacman -S kitty firefox chromium mpv
# Use paru for AUR:
paru -S zen-browser-bin
```

> **Recommendation:** Install Hyprland, terminal emulators, browsers, and media players via
> pacman/AUR. Use Nix/home-manager for CLI tools, development environments, and config management.

### Verification

```bash
# Test nixGL with a simple OpenGL app:
nix run nixpkgs#glxinfo -- -B 2>/dev/null | head -5
# Without nixGL this may fail; with nixGL:
nixGL nix run nixpkgs#glxinfo -- -B 2>/dev/null | head -5
# Should show NVIDIA renderer info
```

---

## Post-Installation Checklist

After completing all sections, verify the full system:

```bash
# System info
uname -r                    # Should show LTS kernel
nvidia-smi                  # Should show GPU
ip addr show enp82s0        # Should show 10.10.10.10/24

# Services
systemctl is-active greetd          # active
systemctl is-active nix-daemon      # active
systemctl is-active systemd-networkd # active
systemctl is-masked sleep.target    # masked

# User
id none                     # Should include wheel, docker, libvirt, plugdev, dialout, video

# Nix
nix --version
home-manager --version

# Hyprland (after login)
hyprctl version
```

---

## Troubleshooting

### NVIDIA dkms fails to build

```bash
# Check dkms status
dkms status
# Rebuild manually
dkms install nvidia/<version> -k $(uname -r)
# Ensure linux-lts-headers are installed
pacman -Q linux-lts-headers
```

### Hyprland fails to start (black screen)

```bash
# Check logs
journalctl -b -u greetd
cat ~/.local/share/hyprland/hyprland.log
# Verify NVIDIA modules loaded
lsmod | grep nvidia_drm
# Verify modeset is enabled
cat /sys/module/nvidia_drm/parameters/modeset
# Should output: Y
```

### Static IP not applying

```bash
# Check networkd status
systemctl status systemd-networkd
networkctl status enp82s0
# Check for config errors
networkctl list
```

### Nix daemon not starting

```bash
journalctl -u nix-daemon
# Check /etc/nix/nix.conf syntax
nix --extra-experimental-features "nix-command flakes" flake show nixpkgs
```

### home-manager switch fails

```bash
# Check for evaluation errors
nix eval .#homeConfigurations."none@station".activationPackage.drvPath
# Run with verbose output
home-manager switch --flake ~/nixflake#none@station --show-trace
```
