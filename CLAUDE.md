# NixOS Flake — Multi-host desktop + homelab server configurations

## Architecture
- `flake.nix` is minimal — imports modules from `parts/`
- `parts/lib.nix` — shared helpers: `mkHost`/`mkServer` builders, `commonModules`, `serverCommonModules`
- `parts/hosts.nix` — all nixosConfigurations. New host? Add here AND in `parts/deploy.nix`
- `parts/deploy.nix` — colmena deployment. Servers deploy as user `odin`
- `modules/nixos/` — system-level (desktop machines)
- `modules/home-manager/` — user-level (desktop machines, home-manager only on desktops)
- `modules/server/` — homelab services (servers have NO home-manager or stylix)
- `hosts/` — per-host config: `default.nix` + `hardware-configuration.nix`
- `profiles/` — shared presets (laptop, desktop, workstation) that enable groups of modules

## Hosts
- **Desktops**: laptop (`none`), vnpc-21 (`odin`), station (`none`)
- **Servers**: pulse, sugar, byob, psychosocial (all on 10.10.x.x subnets)

## Commands
- `just rebuild` — rebuild current host (auto-detects hostname)
- `just verbose` — rebuild with verbose output
- `just deploy-all` — deploy all servers via colmena
- `just deploy <host>` — deploy single host
- `just secrets` / `just secrets-<host>` — edit sops secrets
- `nix fmt` — format all .nix files (nixfmt-rfc-style)
- `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` — test eval

## Rules
- IMPORTANT: Commit all changes before running colmena — colmena requires a clean git tree
- IMPORTANT: Do NOT add Co-Authored-By lines or Claude signatures to commits
- IMPORTANT: New hosts need entries in BOTH `parts/hosts.nix` and `parts/deploy.nix`
- All modules use `options.<namespace>.enable = lib.mkEnableOption` + `config = lib.mkIf cfg.enable`
- Secrets managed with sops-nix — `secrets/secrets.yaml` (shared) + per-host files
- Ollama intentionally binds to `0.0.0.0` with `openFirewall = true` for LAN access — not a security issue

## Gotchas
- Servers use `nixpkgs-unstable`, desktops use `nixos-25.05` (stable) — server modules get the latest NixOS options/packages
- `flake.lock` must NOT be in `.gitignore` — colmena needs it
- `just rebuild` runs `git add .` automatically before building
- Hyprpaper configs must NOT use quotes around file paths
- Server hosts use `mkServer` (no home-manager/stylix), desktops use `mkHost` — don't mix patterns
