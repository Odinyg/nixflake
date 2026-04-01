# NixOS Flake Configuration

A modular, reproducible NixOS configuration using flakes with home-manager integration. Supports multiple desktop hosts and a homelab server fleet, deployed via colmena.

## Hosts

### Desktops

| Host | Description | User | Desktop | Hardware |
|------|-------------|------|---------|----------|
| **VNPC-21** | ThinkPad P53 workstation | odin | Hyprland | Lenovo ThinkPad P53, NVIDIA GPU |
| **laptop** | Portable laptop | none | Hyprland | Generic laptop |
| **station** | Desktop build server | none | Hyprland | AMD desktop, NVIDIA GPU |

### Servers

| Host | Role | Location | Key Services |
|------|------|----------|--------------|
| **psychosocial** | Reverse proxy & gateway | LAN (10.10.30.x) | Caddy, Homepage, Authelia SSO integration |
| **pulse** | Monitoring & observability | LAN (10.10.30.x) | Prometheus, Grafana, Loki, Gatus, ntfy |
| **sugar** | Applications & automation | LAN (10.10.30.x) | Nextcloud, Mealie, n8n, FreshRSS, SearXNG, PostgreSQL |
| **byob** | Media management | LAN (10.10.50.x) | Sonarr, Radarr, Lidarr, Prowlarr, Transmission |
| **spiders** | Auth & VPN (public VPS) | Cantabo VPS (netbird.pytt.io) | Netbird, Authelia, Nginx, Fail2ban |

## Key Features

### Desktop Environment
- **Hyprland** — Modern Wayland compositor with custom animations and keybinds
- **COSMIC** (experimental) — System76's new desktop environment
- **Waybar** — Customized status bar with system monitoring
- **Rofi** — Application launcher with Nord theming
- **SwayNC** — Notification daemon for Wayland

### Development Tools
- **Neovim** — Full IDE via nixvim (LSP, completion, formatting, linting)
- **Zellij** — Terminal multiplexer with persistent sessions
- **Zsh** — Shell with oh-my-zsh, custom aliases, and completions
- **Git** — Configured with lazygit integration
- **Docker** — Container runtime with rootless mode
- **Direnv** — Automatic environment loading per project
- **Language Support** — LSPs and formatters for Nix, Python, Go, Rust, TypeScript, and more

### Theming & Styling
- **Stylix** — Unified theming system across all applications (desktops only)
- **Nord** — Primary color scheme
- **Custom fonts** — Nerd Fonts with Japanese and CJK support

### Homelab & Server Infrastructure
- **Colmena** — Declarative multi-host deployment for all servers
- **Netbird** — WireGuard-based mesh VPN (managed on spiders VPS)
- **Authelia** — SSO/2FA authentication (hosted on spiders, integrated via psychosocial)
- **Caddy** — Reverse proxy with automatic TLS via Cloudflare DNS-01
- **Prometheus + Grafana + Loki** — Full monitoring and log aggregation stack
- **Nextcloud, Mealie, FreshRSS, n8n** — Self-hosted productivity and automation
- **ARR stack** — Sonarr, Radarr, Lidarr, Prowlarr for media management
- **SOPS-nix** — Encrypted secrets with tiered key groups per server

### System Services
- **Tailscale** — Mesh VPN networking
- **Syncthing** — Peer-to-peer file synchronization
- **PipeWire** — Modern audio server with PulseAudio compatibility
- **Flatpak** — Additional application packaging
- **Printing** — CUPS with Brother printer drivers

### Virtualization & Gaming
- **QEMU/KVM** — Virtual machines via virt-manager
- **VirtualBox** — Additional VM support
- **Gaming** (station) — Heroic launcher, Bottles, Steam via Flatpak

## Quick Start

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
   just deploy-all # Deploy all servers via colmena
   just deploy <h> # Deploy a single server
   ```

## Repository Structure

```
.
├── flake.nix                   # Main flake entry point
├── flake.lock                  # Pinned dependency versions
├── justfile                    # Build automation commands
├── CLAUDE.md                   # AI assistant instructions
│
├── parts/                      # Flake-parts modules
│   ├── hosts.nix              # All nixosConfigurations
│   ├── deploy.nix             # Colmena deployment config
│   └── lib.nix                # Shared helpers (mkHost, mkServer)
│
├── hosts/                      # Host-specific configurations
│   ├── laptop/                # Portable laptop
│   ├── vnpc-21/               # ThinkPad P53 workstation
│   ├── station/               # Desktop build server
│   ├── psychosocial/          # Reverse proxy & gateway
│   ├── pulse/                 # Monitoring & observability
│   ├── sugar/                 # Applications & automation
│   ├── byob/                  # Media management
│   └── spiders/               # Auth & VPN (public VPS)
│
├── profiles/                   # Layered configuration profiles
│   ├── base.nix               # Minimal base system
│   ├── laptop.nix             # Laptop-specific (extends base)
│   ├── desktop.nix            # Desktop hardware (extends base)
│   ├── workstation.nix        # Full workstation (extends desktop)
│   ├── hardware/              # Hardware-specific presets
│   └── home-manager/          # Home-manager profile presets
│
├── modules/
│   ├── nixos/                 # System-level modules (desktops)
│   │   ├── hardware/          # GPU, audio, bluetooth, networking
│   │   ├── work/              # Work tools (dev, communication)
│   │   ├── hosted-services/   # Self-hosted services on desktops
│   │   ├── general.nix        # Core system packages
│   │   ├── fonts.nix          # Font configuration
│   │   └── secrets.nix        # SOPS secrets management
│   │
│   ├── home-manager/          # User-level modules (desktops)
│   │   ├── app/               # GUI applications
│   │   ├── cli/               # Terminal tools (neovim, zsh, git)
│   │   ├── desktop/           # Desktop environment (hyprland)
│   │   └── misc/              # Browser, file manager configs
│   │
│   └── server/                # Server modules (homelab + VPS)
│       ├── caddy.nix          # Reverse proxy
│       ├── monitoring.nix     # Prometheus node exporter
│       ├── prometheus.nix     # Metrics collection
│       ├── grafana.nix        # Dashboards
│       ├── loki.nix           # Log aggregation
│       ├── netbird.nix        # Mesh VPN server
│       ├── authelia.nix       # SSO/2FA
│       ├── nextcloud.nix      # File sync
│       ├── arr.nix            # Media stack (sonarr, radarr, etc.)
│       ├── postgresql.nix     # Database
│       └── ...                # 15+ more service modules
│
└── secrets/                    # Encrypted secrets (SOPS)
    ├── secrets.yaml           # Shared desktop secrets
    ├── laptop.yaml            # Per-host secrets
    ├── station.yaml
    ├── vnpc-21.yaml
    ├── byob.yaml
    ├── psychosocial.yaml
    ├── pulse.yaml
    ├── sugar.yaml
    └── spiders.yaml
```

## Architecture

### Profile System (Desktops)
Desktop configurations are layered for maximum reusability:

```
base.nix (core system)
  ├── laptop.nix (base + laptop hardware)
  └── desktop.nix (base + desktop hardware)
       └── workstation.nix (desktop + dev tools)
```

Each desktop host imports a profile and adds host-specific overrides.

Servers do **not** use profiles — they use `serverCommonModules` from `parts/lib.nix`, which provides a minimal base without home-manager or stylix.

### Host Builders
- `mkHost` — Desktop machines (includes home-manager, stylix, stable nixpkgs)
- `mkServer` — Servers (minimal base, no home-manager/stylix, unstable nixpkgs)

### Module Pattern
All optional features use the enable pattern:

```nix
# In host configuration
moduleName.enable = true;
```

## Configuration

### Adding a New Desktop Host

1. **Generate hardware configuration**
   ```bash
   nixos-generate-config --show-hardware-config > hosts/newhost/hardware-configuration.nix
   ```

2. **Create host configuration** in `hosts/newhost/default.nix`

3. **Register in `parts/hosts.nix`** using `mkHost` and in **`parts/deploy.nix`** using `mkColmenaHost`

4. **Build and test**
   ```bash
   just rebuild
   ```

### Adding a New Server

1. **Create host directory** with `default.nix` and `hardware-configuration.nix` in `hosts/newserver/`

2. **Register in `parts/hosts.nix`** using `mkServer` and in **`parts/deploy.nix`** using `mkColmenaServer`

3. **Create secrets file** `secrets/newserver.yaml` and add the host's age key to `.sops.yaml`

4. **Deploy**
   ```bash
   just deploy newserver
   ```

### Enabling/Disabling Features

Most modules use boolean enable options:

```nix
# Desktop environments
hyprland.enable = true;

# Applications
discord.enable = true;
zen-browser.enable = true;

# System features
secrets.enable = true;
gaming.enable = true;

# Server services
server.grafana.enable = true;
server.arr.enable = true;
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

## Secrets Management

Secrets are managed with SOPS-nix using age encryption with a tiered key model:

- **Shared desktop secrets** — `secrets/secrets.yaml` (all desktop hosts)
- **Per-host secrets** — `secrets/<hostname>.yaml` (host-specific)
- **Tiered server keys** — `.sops.yaml` defines key groups (homelab_low, homelab_general, homelab_critical, isolated)

```bash
# Edit shared secrets
just secrets

# Edit per-host secrets
just secrets-<hostname>    # e.g., just secrets-spiders

# Or use the generic target
just secrets-edit <hostname>
```

Secrets are automatically decrypted at boot and placed in `/run/secrets/`.

## Deployment

Servers are deployed via colmena:

```bash
# Deploy all servers
just deploy-all

# Deploy a single server
just deploy <hostname>

# Or use the shorthand
just deploy-spiders
```

Desktop hosts rebuild locally with `just rebuild`.

## Troubleshooting

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
cat ~/.local/share/hyprland/hyprland.log
hyprctl reload
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

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes Wiki](https://nixos.wiki/wiki/Flakes)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Stylix Documentation](https://github.com/danth/stylix)
