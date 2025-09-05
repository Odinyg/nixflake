#!/usr/bin/env bash
set -e

# Bootstrap script for Arch Linux with Nix and Home Manager
# This sets up Arch to use your existing NixOS flake configuration

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     Arch Linux + Nix + Home Manager Bootstrap${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if running on Arch
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}✗ This script must be run on Arch Linux${NC}"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}✗ Don't run this script as root${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Running on Arch Linux as user: $USER${NC}"
echo ""

# Step 1: Install Nix if not present
if ! command -v nix &> /dev/null; then
    echo -e "${BLUE}→ Installing Nix...${NC}"
    
    # Install Nix from Arch repos (better integration)
    sudo pacman -S --needed nix
    
    # Enable nix-daemon
    sudo systemctl enable --now nix-daemon.socket
    sudo systemctl enable --now nix-daemon.service
    
    # Add user to nix-users group
    sudo usermod -aG nix-users $USER
    
    echo -e "${YELLOW}⚠ Added $USER to nix-users group. You may need to log out and back in.${NC}"
    echo -e "${YELLOW}  Or run: newgrp nix-users${NC}"
    echo ""
else
    echo -e "${GREEN}✓ Nix is already installed${NC}"
fi

# Step 2: Configure Nix for flakes
echo -e "${BLUE}→ Configuring Nix for flakes...${NC}"
mkdir -p ~/.config/nix
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
    echo -e "${GREEN}✓ Enabled flakes${NC}"
else
    echo -e "${GREEN}✓ Flakes already enabled${NC}"
fi

# Step 3: Install essential Arch packages for the desktop
echo -e "${BLUE}→ Installing essential Arch packages...${NC}"
ESSENTIAL_PACKAGES=(
    # Core system
    base-devel
    git
    networkmanager
    
    # BTRFS and snapshot tools
    btrfs-progs
    snapper
    snap-pac
    grub-btrfs
    
    # Display server and GPU
    mesa
    vulkan-icd-loader
    xorg-xwayland
    
    # Audio
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
)

# Check which packages need to be installed
MISSING_PACKAGES=()
for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
    if ! pacman -Qq "$pkg" &>/dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "Installing: ${MISSING_PACKAGES[*]}"
    sudo pacman -S --needed "${MISSING_PACKAGES[@]}"
else
    echo -e "${GREEN}✓ All essential packages already installed${NC}"
fi

# Step 4: Install an AUR helper if not present
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo -e "${BLUE}→ Installing yay (AUR helper)...${NC}"
    
    # Install yay from AUR
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
    
    echo -e "${GREEN}✓ Installed yay${NC}"
else
    echo -e "${GREEN}✓ AUR helper already installed${NC}"
fi

# Step 5: Install Home Manager
echo -e "${BLUE}→ Setting up Home Manager...${NC}"
if ! command -v home-manager &> /dev/null; then
    echo "Installing Home Manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    
    # Install home-manager
    nix-shell '<home-manager>' -A install
    
    echo -e "${GREEN}✓ Installed Home Manager${NC}"
else
    echo -e "${GREEN}✓ Home Manager already installed${NC}"
fi

# Step 6: Configure snapper for BTRFS snapshots
echo -e "${BLUE}→ Configuring snapper...${NC}"
if [ ! -f /etc/snapper/configs/root ]; then
    echo -e "${YELLOW}Would you like to configure automatic snapshots with snapper? (y/n)${NC}"
    read -p "> " CONFIGURE_SNAPPER
    
    if [ "$CONFIGURE_SNAPPER" = "y" ]; then
        # Create config for root
        sudo snapper -c root create-config /
        
        # Enable timeline snapshots
        sudo systemctl enable --now snapper-timeline.timer
        sudo systemctl enable --now snapper-cleanup.timer
        
        # Enable grub-btrfs for bootable snapshots
        sudo systemctl enable --now grub-btrfsd
        
        echo -e "${GREEN}✓ Configured snapper with automatic snapshots${NC}"
    fi
else
    echo -e "${GREEN}✓ Snapper already configured${NC}"
fi

# Step 7: Apply Home Manager configuration
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "Next steps:"
echo -e "1. ${YELLOW}Make sure you're in the nix-users group:${NC}"
echo -e "   newgrp nix-users"
echo ""
echo -e "2. ${YELLOW}Apply your Home Manager configuration:${NC}"
echo -e "   cd $(pwd)"
echo -e "   home-manager switch --flake .#${USER}@arch-laptop"
echo ""
echo -e "3. ${YELLOW}After Home Manager switch, sync Arch packages:${NC}"
echo -e "   arch-sync"
echo ""
echo -e "4. ${YELLOW}Check package status:${NC}"
echo -e "   arch-status"
echo ""
echo -e "${BLUE}Available commands after setup:${NC}"
echo -e "  arch-sync   - Install missing declared packages"
echo -e "  arch-adopt  - Show untracked packages to add to config"
echo -e "  arch-status - Show package management status"
echo ""
echo -e "${BLUE}To update your configuration:${NC}"
echo -e "  1. Edit files in $(pwd)"
echo -e "  2. Run: home-manager switch --flake .#${USER}@arch-laptop"
echo -e "  3. Run: arch-sync (if needed)"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"