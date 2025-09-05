#!/usr/bin/env bash
set -e

# =============================================================================
# Arch Linux Installation Script with BTRFS
# This script installs Arch Linux with BTRFS subvolumes optimized for snapshots
# =============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration variables
HOSTNAME="arch-laptop"
USERNAME="none"
TIMEZONE="Europe/Stockholm"  # Change this to your timezone
LOCALE="en_US.UTF-8"

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     Arch Linux BTRFS Installation Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# =============================================================================
# SAFETY CHECK
# =============================================================================
if [ ! -d /sys/firmware/efi ]; then
    echo -e "${RED}✗ This script requires UEFI mode${NC}"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

# =============================================================================
# DISK SELECTION
# =============================================================================
echo -e "${BLUE}→ Available disks:${NC}"
lsblk -d -o NAME,SIZE,MODEL
echo ""

echo -e "${YELLOW}Enter the disk to install on (e.g., nvme0n1, sda):${NC}"
read -p "> /dev/" DISK
DISK="/dev/${DISK}"

if [ ! -b "$DISK" ]; then
    echo -e "${RED}✗ Disk $DISK not found${NC}"
    exit 1
fi

echo -e "${RED}⚠ WARNING: This will ERASE ALL DATA on $DISK${NC}"
echo -e "${YELLOW}Type 'yes' to continue:${NC}"
read -p "> " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Installation cancelled"
    exit 1
fi

# =============================================================================
# PARTITION DISK
# =============================================================================
echo -e "${BLUE}→ Creating partitions...${NC}"

# Wipe disk
wipefs -af "$DISK"
sgdisk -Z "$DISK"

# Create partitions
# 1. EFI partition (512MB)
# 2. Root partition (rest)
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "$DISK"
sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux" "$DISK"

# Get partition names (handles both nvme and sda style)
if [[ "$DISK" == *"nvme"* ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"
else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"
fi

# Format EFI partition
echo -e "${BLUE}→ Formatting EFI partition...${NC}"
mkfs.fat -F32 -n EFI "$EFI_PART"

# =============================================================================
# BTRFS SETUP
# =============================================================================
echo -e "${BLUE}→ Creating BTRFS filesystem...${NC}"
mkfs.btrfs -f -L ARCH "$ROOT_PART"

# Mount for subvolume creation
mount "$ROOT_PART" /mnt

echo -e "${BLUE}→ Creating BTRFS subvolumes...${NC}"
# Create subvolumes
btrfs subvolume create /mnt/@           # Root
btrfs subvolume create /mnt/@home       # Home
btrfs subvolume create /mnt/@nix        # Nix store
btrfs subvolume create /mnt/@log        # Logs
btrfs subvolume create /mnt/@cache      # Cache
btrfs subvolume create /mnt/@tmp        # Temp
btrfs subvolume create /mnt/@snapshots  # Snapshots
btrfs subvolume create /mnt/@swap       # Swap

# Unmount to remount with subvolumes
umount /mnt

# =============================================================================
# MOUNT SUBVOLUMES
# =============================================================================
echo -e "${BLUE}→ Mounting subvolumes...${NC}"

# Mount options for better performance and SSD optimization
MOUNT_OPTS="compress=zstd:1,noatime,space_cache=v2,ssd,discard=async"

# Mount root subvolume
mount -o "$MOUNT_OPTS,subvol=@" "$ROOT_PART" /mnt

# Create mount points
mkdir -p /mnt/{boot,home,nix,.snapshots,var/log,var/cache,tmp,swap}

# Mount other subvolumes
mount -o "$MOUNT_OPTS,subvol=@home" "$ROOT_PART" /mnt/home
mount -o "$MOUNT_OPTS,subvol=@nix" "$ROOT_PART" /mnt/nix
mount -o "$MOUNT_OPTS,subvol=@snapshots" "$ROOT_PART" /mnt/.snapshots
mount -o "$MOUNT_OPTS,subvol=@log" "$ROOT_PART" /mnt/var/log
mount -o "$MOUNT_OPTS,subvol=@cache" "$ROOT_PART" /mnt/var/cache
mount -o "$MOUNT_OPTS,subvol=@tmp" "$ROOT_PART" /mnt/tmp
mount -o "$MOUNT_OPTS,subvol=@swap" "$ROOT_PART" /mnt/swap

# Mount EFI partition
mount "$EFI_PART" /mnt/boot

# =============================================================================
# SWAP FILE
# =============================================================================
echo -e "${BLUE}→ Creating swap file...${NC}"
btrfs filesystem mkswapfile --size 8g /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# =============================================================================
# INSTALL BASE SYSTEM
# =============================================================================
echo -e "${BLUE}→ Installing base system...${NC}"
pacstrap /mnt \
    base linux linux-firmware \
    base-devel \
    btrfs-progs \
    networkmanager \
    neovim nano \
    git \
    intel-ucode amd-ucode \
    efibootmgr

# =============================================================================
# GENERATE FSTAB
# =============================================================================
echo -e "${BLUE}→ Generating fstab...${NC}"
genfstab -U /mnt >> /mnt/etc/fstab

# =============================================================================
# CHROOT CONFIGURATION
# =============================================================================
echo -e "${BLUE}→ Configuring system...${NC}"

arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# Set locale
echo "${LOCALE} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf

# Set hostname
echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
HOSTS

# Configure mkinitcpio for BTRFS
sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Install and configure bootloader (systemd-boot)
bootctl --path=/boot install

# Create bootloader entry
cat > /boot/loader/loader.conf <<LOADER
default arch.conf
timeout 3
console-mode max
editor no
LOADER

# Get root partition UUID
ROOT_UUID=\$(blkid -s UUID -o value ${ROOT_PART})

# Create boot entry
cat > /boot/loader/entries/arch.conf <<ENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=\${ROOT_UUID} rootflags=subvol=@ rw quiet
ENTRY

# Create fallback entry
cat > /boot/loader/entries/arch-fallback.conf <<ENTRY
title   Arch Linux (Fallback)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /amd-ucode.img
initrd  /initramfs-linux-fallback.img
options root=UUID=\${ROOT_UUID} rootflags=subvol=@ rw
ENTRY

# Enable NetworkManager
systemctl enable NetworkManager

# Set root password
echo -e "${YELLOW}Set root password:${NC}"
passwd

# Create user
useradd -m -G wheel -s /bin/bash ${USERNAME}
echo -e "${YELLOW}Set password for ${USERNAME}:${NC}"
passwd ${USERNAME}

# Configure sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
EOF

# =============================================================================
# INSTALL ADDITIONAL PACKAGES
# =============================================================================
echo -e "${BLUE}→ Installing additional packages...${NC}"

arch-chroot /mnt /bin/bash <<EOF
# Install essential packages for the desktop
pacman -S --noconfirm \
    grub-btrfs \
    snapper \
    snap-pac \
    iwd \
    dhcpcd \
    man-db \
    man-pages \
    bash-completion \
    wget \
    curl \
    openssh \
    rsync \
    htop \
    which
EOF

# =============================================================================
# SNAPPER CONFIGURATION
# =============================================================================
echo -e "${BLUE}→ Configuring snapper...${NC}"

arch-chroot /mnt /bin/bash <<EOF
# Remove default snapper config if it exists
umount /.snapshots 2>/dev/null || true
rm -rf /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a

# Configure snapper
sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="4"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="2"/' /etc/snapper/configs/root
sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

# Enable snapper services
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable grub-btrfsd
EOF

# =============================================================================
# FINAL SETUP
# =============================================================================
echo -e "${BLUE}→ Creating post-install script...${NC}"

cat > /mnt/home/${USERNAME}/post-install.sh <<'POSTINSTALL'
#!/bin/bash
# Post-installation script to run after first boot

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Running post-installation setup...${NC}"

# Clone the nixflake repository
if [ ! -d "$HOME/nixflake" ]; then
    echo -e "${BLUE}→ Cloning nixflake repository...${NC}"
    git clone https://github.com/Odinyg/nixflake.git "$HOME/nixflake"
    cd "$HOME/nixflake"
    git checkout arch-migration
fi

# Run the bootstrap script
cd "$HOME/nixflake"
./arch-modules/bootstrap-arch.sh

echo -e "${GREEN}✓ Post-installation complete!${NC}"
echo "You can now run: home-manager switch --flake .#${USER}@arch-laptop"
POSTINSTALL

chmod +x /mnt/home/${USERNAME}/post-install.sh
arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/post-install.sh

# =============================================================================
# COMPLETION
# =============================================================================
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}     Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Unmount and reboot:"
echo "   umount -R /mnt"
echo "   reboot"
echo ""
echo "2. After reboot, login as ${USERNAME} and run:"
echo "   ./post-install.sh"
echo ""
echo "3. Then apply the Home Manager configuration:"
echo "   cd ~/nixflake"
echo "   home-manager switch --flake .#${USERNAME}@arch-laptop"
echo ""
echo -e "${BLUE}System information:${NC}"
echo "  Hostname: ${HOSTNAME}"
echo "  Username: ${USERNAME}"
echo "  Disk: ${DISK}"
echo "  BTRFS with automatic snapshots configured"
echo ""