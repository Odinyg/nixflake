{ config, pkgs, lib, ... }: 
let
  # Common packages for all Arch machines (system-level only)
  commonPackages = [
    # Core system
    "base-devel"
    "git"
    "networkmanager"
    
    # Hyprland compositor (system-level)
    "hyprland"
    "wlroots"
    "xwayland"
    
    # Wayland system integration
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "polkit-kde-agent"
    "qt5-wayland"
    "qt6-wayland"
    
    # System clipboard (needed by many apps)
    "wl-clipboard"
    
    # Lock and idle (system-level)
    "swaylock"
    "swayidle"
    "hypridle"
    "hyprlock"
    
    # Audio system (must be system-level)
    "pipewire"
    "wireplumber"
    "pipewire-pulse"
    "pipewire-alsa"
    "pipewire-jack"
    
    # Bluetooth (system service)
    "bluez"
    "bluez-utils"
    
    # Graphics and video acceleration
    "mesa"
    "vulkan-icd-loader"
    "libva"
    "libva-utils"
  ];
  
  # Machine-specific packages
  machinePackages = {
    arch-laptop = [
      "tlp"
      "powertop"
      "brightnessctl"
      "acpi"
      "thermald"
    ];
  };
  
  # Packages to ignore in checks (manually managed)
  ignoredPackages = [
    "linux"
    "linux-firmware"
    "linux-headers"
    "base"
    "grub"
    "efibootmgr"
    "os-prober"
    "yay"
    "paru"
    "snapper"
    "snap-pac"
    "grub-btrfs"
    "btrfs-progs"
  ];
  
  # Get hostname from config or environment
  hostname = config._module.args.hostname or "arch-laptop";
  
  # Combine packages for this machine
  allPackages = commonPackages ++ (machinePackages.${hostname} or []);
  
in {
  options.archPackages = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Arch package management integration";
    };
    
    additionalPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional Arch packages to track";
    };
    
    additionalIgnored = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional packages to ignore";
    };
  };
  
  config = lib.mkIf config.archPackages.enable {
    # Write declared packages
    home.file.".config/arch-packages/declared.txt".text = 
      lib.concatStringsSep "\n" (allPackages ++ config.archPackages.additionalPackages);
    
    # Write ignored packages
    home.file.".config/arch-packages/ignored.txt".text = 
      lib.concatStringsSep "\n" (ignoredPackages ++ config.archPackages.additionalIgnored);
    
    # Check packages during home-manager switch
    home.activation.checkArchPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -f /etc/arch-release ]; then
        ${pkgs.bash}/bin/bash -c '
          RED="\033[0;31m"
          YELLOW="\033[1;33m"
          GREEN="\033[0;32m"
          BLUE="\033[0;34m"
          NC="\033[0m"
          
          echo -e "\n''${BLUE}📦 Checking Arch packages...''${NC}"
          
          # Get lists
          DECLARED=$(cat ~/.config/arch-packages/declared.txt 2>/dev/null | sort -u)
          IGNORED=$(cat ~/.config/arch-packages/ignored.txt 2>/dev/null | sort -u)
          
          # Check if pacman is available
          if ! command -v pacman &> /dev/null; then
            echo -e "''${YELLOW}⚠ pacman not found, skipping Arch package check''${NC}"
            exit 0
          fi
          
          INSTALLED=$(pacman -Qqe 2>/dev/null | sort)
          
          # Filter out ignored packages
          INSTALLED_FILTERED=$(comm -23 <(echo "$INSTALLED") <(echo "$IGNORED"))
          
          # Find differences
          MISSING=$(comm -13 <(echo "$INSTALLED_FILTERED") <(echo "$DECLARED"))
          EXTRA=$(comm -23 <(echo "$INSTALLED_FILTERED") <(echo "$DECLARED"))
          
          # Report missing
          if [ -n "$MISSING" ]; then
            COUNT=$(echo "$MISSING" | wc -l)
            echo -e "''${YELLOW}⚠ Missing packages: $COUNT''${NC}"
            echo "$MISSING" | head -5 | sed "s/^/    /"
            [ $COUNT -gt 5 ] && echo "    ... and $((COUNT - 5)) more"
            echo -e "    ''${BLUE}→ Run ''${GREEN}arch-sync''${BLUE} to install''${NC}"
          fi
          
          # Report extra
          if [ -n "$EXTRA" ]; then
            COUNT=$(echo "$EXTRA" | wc -l)
            echo -e "''${YELLOW}ℹ Extra packages: $COUNT''${NC}"
            echo "$EXTRA" | head -5 | sed "s/^/    /"
            [ $COUNT -gt 5 ] && echo "    ... and $((COUNT - 5)) more"
            echo -e "    ''${BLUE}→ Run ''${GREEN}arch-adopt''${BLUE} to add to flake''${NC}"
          fi
          
          [ -z "$MISSING" ] && [ -z "$EXTRA" ] && echo -e "''${GREEN}✓ All packages in sync!''${NC}"
          echo ""
        '
      else
        echo "Not on Arch Linux, skipping package check"
      fi
    '';
    
    # Sync command - installs missing packages only
    home.packages = with pkgs; [
      (writeShellScriptBin "arch-sync" ''
        #!/usr/bin/env bash
        set -e
        
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        YELLOW='\033[1;33m'
        NC='\033[0m'
        
        if [ ! -f /etc/arch-release ]; then
          echo -e "''${YELLOW}Not on Arch Linux''${NC}"
          exit 1
        fi
        
        echo -e "''${BLUE}📦 Syncing Arch packages...''${NC}\n"
        
        DECLARED=$(cat ~/.config/arch-packages/declared.txt 2>/dev/null | sort -u)
        INSTALLED=$(pacman -Qqe | sort)
        MISSING=$(comm -13 <(echo "$INSTALLED") <(echo "$DECLARED"))
        
        if [ -n "$MISSING" ]; then
          echo -e "''${GREEN}Installing missing packages:''${NC}"
          echo "$MISSING" | sed 's/^/  /'
          echo ""
          sudo pacman -S --needed $MISSING
        else
          echo -e "''${GREEN}✓ No packages to install''${NC}"
        fi
      '')
      
      # Adopt command - shows packages to add to flake
      (writeShellScriptBin "arch-adopt" ''
        #!/usr/bin/env bash
        
        if [ ! -f /etc/arch-release ]; then
          echo "Not on Arch Linux"
          exit 1
        fi
        
        DECLARED=$(cat ~/.config/arch-packages/declared.txt 2>/dev/null | sort -u)
        IGNORED=$(cat ~/.config/arch-packages/ignored.txt 2>/dev/null | sort -u)
        INSTALLED=$(pacman -Qqe | sort)
        
        # Filter out ignored and declared
        CANDIDATES=$(comm -23 <(echo "$INSTALLED") <(cat <(echo "$DECLARED") <(echo "$IGNORED") | sort -u))
        
        if [ -z "$CANDIDATES" ]; then
          echo "No packages to adopt"
          exit 0
        fi
        
        echo "Packages installed but not tracked:"
        echo ""
        echo "$CANDIDATES" | nl
        echo ""
        echo "To add packages:"
        echo "1. Edit arch-modules/arch-packages.nix"
        echo "2. Add to commonPackages or machinePackages.arch-laptop"
        echo "3. Run: home-manager switch --flake .#none@arch-laptop"
        echo ""
        echo "List saved to: /tmp/arch-packages-to-adopt.txt"
        echo "$CANDIDATES" > /tmp/arch-packages-to-adopt.txt
      '')
      
      # Status command
      (writeShellScriptBin "arch-status" ''
        #!/usr/bin/env bash
        
        if [ ! -f /etc/arch-release ]; then
          echo "Not on Arch Linux"
          exit 0
        fi
        
        DECLARED=$(cat ~/.config/arch-packages/declared.txt 2>/dev/null | wc -l)
        IGNORED=$(cat ~/.config/arch-packages/ignored.txt 2>/dev/null | wc -l)
        INSTALLED=$(pacman -Qqe 2>/dev/null | wc -l)
        
        echo "📦 Arch Package Status:"
        echo "  Installed: $INSTALLED total"
        echo "  Declared:  $DECLARED tracked"
        echo "  Ignored:   $IGNORED unmanaged"
        echo ""
        echo "Commands:"
        echo "  arch-sync   - Install missing declared packages"
        echo "  arch-adopt  - Show untracked packages to add"
        echo "  arch-status - Show this status"
      '')
    ];
  };
}