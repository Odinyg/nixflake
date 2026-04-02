# Station — Arch Linux System Services Guide

Complete reference for installing and configuring all system services that station currently runs under NixOS. Covers package ownership, installation commands, configuration, and verification for each service.

> **Station user:** `none`  
> **Static IP:** `10.10.10.10` (Servers VLAN, enp82s0)  
> **GPU:** NVIDIA (proprietary drivers, CUDA enabled)  
> **Monitors:** DP-1 (1920×1080@120) + HDMI-A-1 (3840×2160@60)

---

## Section 1: Package Ownership Table

| Component | Owner | Package | Notes |
|-----------|-------|---------|-------|
| Kernel | pacman | `linux-lts` | Stable for NVIDIA dkms |
| NVIDIA drivers | pacman | `nvidia-dkms` | dkms for kernel compat; use `latest` driver series |
| Hyprland | pacman | `hyprland` | System WM |
| Greetd | pacman | `greetd greetd-tuigreet` | Display manager; replaces SDDM |
| Docker | pacman | `docker docker-compose` | System daemon (non-rootless) |
| QEMU/KVM | pacman | `qemu-full libvirt virt-manager dnsmasq swtpm` | System virtualization; SPICE + TPM support |
| Tailscale | pacman | `tailscale` | System VPN; `--accept-routes` flag |
| Netbird | AUR | `netbird` | Mesh VPN client (use paru/yay); wt0 interface, port 51820 |
| Syncthing | pacman | `syncthing` | File sync; runs as user `none` |
| Sunshine | AUR | `sunshine` | Game streaming (use paru/yay); needs `cap_sys_admin` |
| SSH (server) | pacman | `openssh` | Key-only auth, no password/root login |
| Ollama | AUR | `ollama-cuda` | GPU inference (CUDA); binds 0.0.0.0:11434 |
| PostgreSQL | pacman | `postgresql` | Version 17; `postgres.local` alias |
| PipeWire | pacman | `pipewire pipewire-pulse pipewire-alsa wireplumber` | Audio; ALSA + PulseAudio compat + 32-bit |
| Bluetooth | pacman | `bluez bluez-utils blueman` | Bluetooth stack; power on boot |
| Polkit | pacman | `polkit polkit-gnome gnome-keyring` | Privilege escalation; GNOME keyring integration |
| XDG Portals | pacman | `xdg-desktop-portal-hyprland xdg-desktop-portal-gtk` | Screensharing under Hyprland |
| 1Password | AUR | `1password 1password-cli` | Password manager |
| ProtonVPN | AUR | `proton-vpn-gtk-app` | VPN GUI; uses systemd-resolved |
| Open WebUI | pacman/AUR | `open-webui` or Docker | LLM UI; OAuth via Authelia at auth.pytt.io |
| Nix | manual | (install script) | Package manager; flakes + nix-command enabled |
| Flatpak | pacman | `flatpak` | Additional apps (Bottles, Heroic) |
| Steam | pacman | `steam` | Gaming platform; Proton + GameMode + Gamescope |
| GameMode | pacman | `gamemode` | CPU/GPU performance governor during gaming |
| Gamescope | pacman | `gamescope` | Wayland compositor for gaming sessions |
| Wine | pacman | `wine-wow64 winetricks` | Windows compatibility layer |
| All user CLI tools | Nix/HM | home-manager | Managed declaratively via `none@station` |
| All user GUI apps | Nix/HM | home-manager | May need nixGL for non-NixOS |
| Theming | Nix/HM | stylix home module | HM-managed; Nord dark theme |

---

## Section 2: Service Installation & Configuration

### 2.1 Docker

```bash
# Install
sudo pacman -S docker docker-compose

# Add user to docker group
sudo usermod -aG docker none

# Enable and start
sudo systemctl enable --now docker

# Verify
docker run --rm hello-world
docker compose version
```

> Station uses **non-rootless** Docker (system daemon). The `none` user must be in the `docker` group.

---

### 2.2 QEMU/KVM + libvirt

```bash
# Install
sudo pacman -S qemu-full libvirt virt-manager dnsmasq swtpm edk2-ovmf

# Add user to required groups
sudo usermod -aG libvirt none
sudo usermod -aG kvm none

# Enable and start libvirtd
sudo systemctl enable --now libvirtd

# Enable default network (NAT)
sudo virsh net-autostart default
sudo virsh net-start default

# Verify
virt-manager  # should open GUI
virsh list --all
```

**SPICE USB redirection** (for passing USB devices to VMs):
```bash
sudo pacman -S spice-vdagent
sudo systemctl enable --now spice-vdagentd
```

> Station config: `onBoot = "start"`, `onShutdown = "shutdown"` — VMs auto-start/stop with host.  
> OVMF (UEFI) and swtpm (TPM) are enabled for Windows 11 VMs.

---

### 2.3 PostgreSQL

```bash
# Install
sudo pacman -S postgresql

# Initialize database cluster (as postgres user)
sudo -u postgres initdb -D /var/lib/postgres/data

# Enable and start
sudo systemctl enable --now postgresql

# Verify
sudo -u postgres psql -c '\l'
```

**Restore from backup:**
```bash
# Restore a pg_dump file
sudo -u postgres psql < backup.sql

# Or restore a directory-format dump
sudo -u postgres pg_restore -d mydb /path/to/backup/
```

**Create a user/database:**
```bash
sudo -u postgres createuser --interactive none
sudo -u postgres createdb mydb -O none
```

> Station runs PostgreSQL 17. The `postgres.local` hostname alias is set in `/etc/hosts`.

---

### 2.4 Tailscale

```bash
# Install
sudo pacman -S tailscale

# Enable and start
sudo systemctl enable --now tailscaled

# Authenticate (interactive)
sudo tailscale up --accept-routes

# Or with auth key (non-interactive)
sudo tailscale up --accept-routes --auth-key=<tskey-auth-...>

# Verify
tailscale status
tailscale ip
```

> Station uses `--accept-routes` to receive subnet routes from the tailnet.  
> The `tailscale0` interface is trusted in the firewall.

---

### 2.5 Netbird

```bash
# Install from AUR
paru -S netbird
# or: yay -S netbird

# Enable systemd-resolved (required for split DNS)
sudo systemctl enable --now systemd-resolved

# Configure loose reverse path filtering (required for routing)
echo 'net.ipv4.conf.all.rp_filter = 2' | sudo tee /etc/sysctl.d/99-netbird.conf
sudo sysctl -p /etc/sysctl.d/99-netbird.conf

# Start Netbird and connect
sudo netbird up

# Or with management URL and key
sudo netbird up --management-url https://netbird.pytt.io --setup-key <key>

# Enable as system service
sudo systemctl enable --now netbird

# Verify
netbird status
ip addr show wt0
```

> Station uses interface `wt0` on port `51820`. The `wt0` interface is trusted in the firewall.  
> Netbird registers DNS via D-Bus with systemd-resolved for split DNS.

---

### 2.6 Syncthing

```bash
# Install
sudo pacman -S syncthing

# Option A: Run as system service for user 'none'
sudo systemctl enable --now syncthing@none

# Option B: Run as user service (preferred)
systemctl --user enable --now syncthing

# Verify — open web UI
xdg-open http://127.0.0.1:8384
```

> Station config: data dir = `~/Documents`, config dir = `~/.config/syncthing`.  
> `overrideDevices = false` — devices are managed via the web UI, not declaratively.

---

### 2.7 Sunshine (Game Streaming)

```bash
# Install from AUR
paru -S sunshine
# or: yay -S sunshine

# Grant required capabilities (needed for input capture)
sudo setcap cap_sys_admin+p $(which sunshine)

# Enable Avahi for mDNS discovery
sudo systemctl enable --now avahi-daemon

# Enable and start Sunshine
sudo systemctl enable --now sunshine

# Verify — open web UI
xdg-open https://localhost:47990
```

**Config file:** `~/.config/sunshine/sunshine.conf`
```ini
sunshine_name = station
origin_web_ui_allowed = wan
resolutions = [
  1920x1080,
  2560x1440,
  3840x2160
]
```

> Sunshine opens firewall ports automatically. The web UI is accessible from WAN (`origin_web_ui_allowed = wan`).  
> Station hostname is used as the stream name.

---

### 2.8 Ollama (CUDA)

```bash
# Install CUDA-enabled build from AUR
paru -S ollama-cuda
# or: yay -S ollama-cuda

# Enable and start
sudo systemctl enable --now ollama

# Verify GPU detection
ollama ps
nvidia-smi  # should show ollama process using GPU

# Pull a model
ollama pull llama3.2
ollama run llama3.2
```

**TLS certificate for LAN HTTPS access** (mirrors NixOS setup):
```bash
# Generate self-signed cert
sudo mkdir -p /var/lib/ollama/tls
sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
  -days 3650 -nodes -subj "/CN=ollama" \
  -addext "subjectAltName=IP:10.10.10.10,DNS:ollama.local" \
  -keyout /var/lib/ollama/tls/key.pem \
  -out /var/lib/ollama/tls/cert.pem
sudo chown -R ollama:ollama /var/lib/ollama/tls
```

**Ollama systemd override** (`/etc/systemd/system/ollama.service.d/override.conf`):
```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_TLS_CERT=/var/lib/ollama/tls/cert.pem"
Environment="OLLAMA_TLS_KEY=/var/lib/ollama/tls/key.pem"
```

> Ollama intentionally binds to `0.0.0.0:11434` for LAN access — this is expected behavior.  
> Add `127.0.0.1 ollama.local` to `/etc/hosts`.

---

### 2.9 SSH Server

```bash
# Install
sudo pacman -S openssh

# Configure key-only auth
sudo nano /etc/ssh/sshd_config
```

**`/etc/ssh/sshd_config` settings:**
```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
```

**Add authorized keys:**
```bash
mkdir -p ~/.ssh
cat >> ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEb3q553HODR8Yipt69tmLrGOqLTfde/G8yntaitNkA3
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINezFWDmtlGHBF674DcsNi+wDMrSp13pNX1lo4RcJTMm
EOF
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

```bash
# Enable and start
sudo systemctl enable --now sshd

# Verify
ssh -v none@10.10.10.10
```

---

### 2.10 PipeWire (Audio)

```bash
# Install
sudo pacman -S pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol

# Enable as user services (NOT system services)
systemctl --user enable --now pipewire
systemctl --user enable --now pipewire-pulse
systemctl --user enable --now wireplumber

# Verify
pactl info | grep "Server Name"
wpctl status
```

> PipeWire runs as a user service, not system. Enable 32-bit ALSA support for Wine/Steam:
```bash
sudo pacman -S lib32-pipewire
```

---

### 2.11 Bluetooth

```bash
# Install
sudo pacman -S bluez bluez-utils blueman

# Enable and start
sudo systemctl enable --now bluetooth

# Configure power-on-boot
sudo nano /etc/bluetooth/main.conf
```

**`/etc/bluetooth/main.conf`:**
```ini
[Policy]
AutoEnable=true

[General]
UserspaceHID=true
```

```bash
# Verify
bluetoothctl show
bluetoothctl scan on
```

> `blueman` provides the system tray applet (`blueman-applet`) and manager GUI (`blueman-manager`).  
> Start `blueman-applet` in Hyprland `exec-once`.

---

## Section 3: Display Stack

### 3.1 Greetd + tuigreet

```bash
# Install
sudo pacman -S greetd greetd-tuigreet

# Configure
sudo nano /etc/greetd/config.toml
```

**`/etc/greetd/config.toml`:**
```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland"
user = "greeter"
```

```bash
# Enable greetd (replaces getty on tty1)
sudo systemctl enable greetd
sudo systemctl disable getty@tty1  # optional, greetd handles this
```

---

### 3.2 Hyprland Session

```bash
# Install Hyprland
sudo pacman -S hyprland

# Hyprland is launched by greetd — no .desktop session file needed for tuigreet --cmd
# But for other greeters, create:
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
```

**NVIDIA environment variables** — add to `/etc/environment` or Hyprland's `exec-once`:
```bash
# /etc/environment
GBM_BACKEND=nvidia-drm
WLR_NO_HARDWARE_CURSORS=1
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NIXOS_OZONE_WL=1
```

**Kernel parameters** — add to bootloader:
```
nvidia-drm.modeset=1 nvidia_drm.fbdev=1
```

---

### 3.3 PAM for Swaylock

> **Note:** Station has swaylock **disabled** (`programs.swaylock.enable = lib.mkForce false`) due to crashes on HDMI disconnect. Skip this if not using swaylock.

If re-enabling swaylock, create `/etc/pam.d/swaylock`:
```
auth include login
```

---

### 3.4 Polkit

```bash
# Install
sudo pacman -S polkit polkit-gnome gnome-keyring

# polkit daemon starts automatically via D-Bus activation
# Add polkit-gnome agent to Hyprland autostart:
# In ~/.config/hypr/hyprland.conf:
# exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
```

**Polkit rule for power management** (`/etc/polkit-1/rules.d/10-power.rules`):
```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.power-off" ||
        action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.suspend" ||
        action.id == "org.freedesktop.login1.hibernate") {
        if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    }
});
```

**GNOME Keyring PAM integration** — add to `/etc/pam.d/login` and `/etc/pam.d/greetd`:
```
auth     optional  pam_gnome_keyring.so
session  optional  pam_gnome_keyring.so auto_start
```

---

### 3.5 XDG Portals (Screensharing)

```bash
# Install
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Verify portals are running (after Hyprland starts)
systemctl --user status xdg-desktop-portal-hyprland
systemctl --user status xdg-desktop-portal
```

**`~/.config/xdg-desktop-portal/hyprland-portals.conf`:**
```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=gtk
```

---

## Section 4: Gaming Stack

### 4.1 Steam

```bash
# Enable multilib repository first (edit /etc/pacman.conf, uncomment [multilib])
sudo pacman -S steam

# Enable and start Steam
steam

# Install Proton (via Steam > Settings > Compatibility)
# Or install Proton-GE from AUR:
paru -S proton-ge-custom
```

### 4.2 GameMode + Gamescope

```bash
# Install
sudo pacman -S gamemode gamescope

# Add user to gamemode group
sudo usermod -aG gamemode none

# Verify GameMode
gamemoded -t

# Use with a game
gamemoderun %command%  # in Steam launch options
```

**GameMode config** (`/etc/gamemode.ini`):
```ini
[general]
renice=10
ioprio=7
inhibit_screensaver=1

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
```

### 4.3 Heroic Games Launcher

```bash
# AUR
paru -S heroic-games-launcher-bin

# Or Flatpak
flatpak install flathub com.heroicgameslauncher.hgl
```

### 4.4 Bottles (Wine Manager)

```bash
# Flatpak (recommended — sandboxed)
flatpak install flathub com.usebottles.bottles

# Or AUR
paru -S bottles
```

### 4.5 Wine + Winetricks

```bash
# Install (64+32-bit)
sudo pacman -S wine-wow64 winetricks protontricks

# 32-bit graphics support
sudo pacman -S lib32-vulkan-icd-loader lib32-nvidia-utils
```

### 4.6 Enable Flatpak

```bash
sudo pacman -S flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

---

## Section 5: Print Setup

```bash
# Install CUPS
sudo pacman -S cups cups-pdf

# Enable and start
sudo systemctl enable --now cups

# Install Avahi for network printer discovery
sudo pacman -S avahi nss-mdns

# Enable Avahi
sudo systemctl enable --now avahi-daemon

# Configure nss-mdns — edit /etc/nsswitch.conf
# Change: hosts: ... resolve [!UNAVAIL=return] dns ...
# To:     hosts: ... mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns ...

# Add printer via web UI
xdg-open http://localhost:631
```

---

## Section 6: ProtonVPN

```bash
# Install GUI from AUR
paru -S proton-vpn-gtk-app

# Enable systemd-resolved (required)
sudo systemctl enable --now systemd-resolved

# Launch GUI
proton-vpn-gtk-app

# CLI alternative
paru -S protonvpn-cli
protonvpn-cli login <username>
protonvpn-cli connect --fastest
```

> ProtonVPN on Arch uses the GTK app or CLI — different from the NixOS module approach.  
> systemd-resolved is required for DNS leak prevention.

---

## Section 7: Open WebUI

Open WebUI connects to the local Ollama instance and authenticates via Authelia OAuth.

### Option A: Native package (AUR)

```bash
paru -S open-webui

# Configure environment
sudo tee /etc/open-webui.env << 'EOF'
OLLAMA_API_BASE_URL=http://127.0.0.1:11434
WEBUI_AUTH=true
ENABLE_OAUTH_SIGNUP=true
OAUTH_PROVIDER_NAME=Authelia
OAUTH_CLIENT_ID=open-webui
OAUTH_CLIENT_SECRET=<secret-from-sops>
OPENID_PROVIDER_URL=https://auth.pytt.io/.well-known/openid-configuration
OAUTH_SCOPES=openid profile email
EOF

sudo systemctl enable --now open-webui
```

### Option B: Docker container

```bash
# With CUDA GPU support
docker run -d --name open-webui \
  --gpus all \
  -p 3000:8080 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434 \
  -e WEBUI_AUTH=true \
  -e ENABLE_OAUTH_SIGNUP=true \
  -e OAUTH_PROVIDER_NAME=Authelia \
  -e OAUTH_CLIENT_ID=open-webui \
  -e OAUTH_CLIENT_SECRET=<secret-from-sops> \
  -e OPENID_PROVIDER_URL=https://auth.pytt.io/.well-known/openid-configuration \
  -e OAUTH_SCOPES="openid profile email" \
  ghcr.io/open-webui/open-webui:cuda

# Auto-restart on boot
docker update --restart unless-stopped open-webui

# Verify
xdg-open http://localhost:3000
```

> The `OAUTH_CLIENT_SECRET` is stored in SOPS at `secrets/station.yaml` under `openwebui_oauth_client_secret`.  
> Open WebUI is accessible at `http://open-webui.local:3000` (add to `/etc/hosts`).

---

## Section 8: NVIDIA Drivers

```bash
# Install LTS kernel + NVIDIA dkms
sudo pacman -S linux-lts linux-lts-headers nvidia-dkms nvidia-utils lib32-nvidia-utils

# Add kernel parameters to bootloader (GRUB)
sudo nano /etc/default/grub
# GRUB_CMDLINE_LINUX_DEFAULT="... nvidia-drm.modeset=1 nvidia_drm.fbdev=1"
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Disable NVIDIA power management services (station never sleeps)
sudo systemctl mask nvidia-suspend nvidia-hibernate nvidia-resume

# Verify
nvidia-smi
```

**`/etc/modprobe.d/nvidia.conf`:**
```
options nvidia-drm modeset=1 fbdev=1
```

---

## Section 9: Static Network Configuration

Station uses a static IP on the Servers VLAN. With NetworkManager:

```bash
# Create static connection for enp82s0
nmcli con add type ethernet \
  con-name "servers-vlan" \
  ifname enp82s0 \
  ipv4.method manual \
  ipv4.addresses "10.10.10.10/24" \
  ipv4.gateway "10.10.10.1" \
  ipv4.dns "10.10.10.1,1.1.1.1" \
  connection.autoconnect yes

nmcli con up "servers-vlan"
```

**`/etc/hosts` additions:**
```
127.0.0.1 ollama.local
127.0.0.1 syncthing.local
127.0.0.1 sunshine.local
127.0.0.1 postgres.local
127.0.0.1 open-webui.local
```

---

## Section 10: Power Management (Disable Sleep)

Station is a desktop that should never sleep:

```bash
# Disable sleep/suspend/hibernate via systemd
sudo mkdir -p /etc/systemd/sleep.conf.d
sudo tee /etc/systemd/sleep.conf.d/nosleep.conf << 'EOF'
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF

# Disable lid switch actions (logind)
sudo tee /etc/systemd/logind.conf.d/nolidswitch.conf << 'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore
EOF

sudo systemctl restart systemd-logind
```

---

## Quick Reference: Group Memberships

After all services are installed, ensure `none` is in all required groups:

```bash
sudo usermod -aG docker,libvirt,kvm,gamemode,wheel,networkmanager,plugdev,dialout none

# Verify
groups none
# Expected: none wheel networkmanager plugdev dialout docker libvirt kvm gamemode
```

> Group changes require logout/login (or `newgrp <group>`) to take effect.

---

## Quick Reference: Services to Enable

```bash
# System services
sudo systemctl enable --now docker
sudo systemctl enable --now libvirtd
sudo systemctl enable --now postgresql
sudo systemctl enable --now tailscaled
sudo systemctl enable --now netbird
sudo systemctl enable --now syncthing@none
sudo systemctl enable --now sunshine
sudo systemctl enable --now sshd
sudo systemctl enable --now bluetooth
sudo systemctl enable --now avahi-daemon
sudo systemctl enable --now cups
sudo systemctl enable greetd

# User services (run as none)
systemctl --user enable --now pipewire
systemctl --user enable --now pipewire-pulse
systemctl --user enable --now wireplumber
```
