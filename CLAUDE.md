# NixOS Flake — Multi-host desktop + homelab server configurations

## Architecture
- `flake.nix` is minimal — imports modules from `parts/`
- `parts/lib.nix` — shared helpers: `hostModules`/`serverModules` builders, `commonModules`, `serverCommonModules`, `pkgs-unstable`
- `parts/hosts.nix` — all nixosConfigurations (`mkHost`/`mkServer` wrappers). New host? Add here AND in `parts/deploy.nix`
- `parts/deploy.nix` — colmena deployment. Servers deploy as user `odin`
- `parts/dev.nix` — perSystem config: formatter (`nixfmt-rfc-style`)
- `modules/nixos/` — system-level (desktop machines)
- `modules/home-manager/` — user-level (desktop machines, home-manager only on desktops)
- `modules/server/` — homelab services (servers have NO home-manager or stylix)
- `hosts/` — per-host config: `default.nix` + `hardware-configuration.nix`
- `profiles/` — shared presets (laptop, desktop, workstation) that enable groups of modules

## Hosts
- **Desktops**: laptop (`none`), VNPC-21 (`odin`), station (`none`)
- **Servers (homelab)**: pulse, sugar, byob, psychosocial, nero (LAN, 10.10.x.x subnets)
- **Servers (VPS)**: spiders (public Cantabo VPS at netbird.pytt.io — runs netbird + authelia + nginx)
- **Installer**: minimal ISO with SSH key baked in — for bootstrapping new hosts

## Commands
- `just rebuild` — rebuild current host (auto-detects hostname)
- `just verbose` — rebuild with verbose output
- `just upgrade` — update flake inputs + rebuild
- `just boot` — build new boot configuration
- `just gc` — clean generations older than 14 days
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
- All services are exposed via `*.pytt.io` subdomains through Caddy on psychosocial
- `let cfg = config.<name>;` binding is MANDATORY in all modules with an enable option
- Config guard is ALWAYS `lib.mkIf cfg.enable` — never inline `config.<name>.enable`
- nixos/home-manager: root namespace (`options.<name>`); server: nested (`options.server.<name>`)
- Single file default; directory with `default.nix` only when 3+ sub-modules needed
- Cross-module refs (`config.user`, `config.sops.*`, `config.home-manager.*`, `config.smbmount.*`) stay as `config.X` — never replace with `cfg`

## Module Patterns
**nixos** — `options.<name>`, root namespace:
```nix
{ lib, config, pkgs, ... }:
let cfg = config.<name>; in
{
  options.<name>.enable = lib.mkEnableOption "<description>";
  config = lib.mkIf cfg.enable {
    # system-level config
  };
}
```

**home-manager** — `options.<name>`, wraps user:
```nix
{ lib, config, pkgs, ... }:
let cfg = config.<name>; in
{
  options.<name>.enable = lib.mkEnableOption "<description>";
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.user} = {
      # user-level config
    };
  };
}
```

**server** — `options.server.<name>`, nested namespace:
```nix
{ lib, config, pkgs, ... }:
let cfg = config.server.<name>; in
{
  options.server.<name> = {
    enable = lib.mkEnableOption "<description>";
    port = lib.mkOption { type = lib.types.port; default = XXXX; };
  };
  config = lib.mkIf cfg.enable {
    # service config
  };
}
```

## External flake-sourced modules
- **second-brain**: sourced from the `brain` flake input (`git+https://git.pytt.io/odin/Brain`), not vendored locally. Lives on **nero** (`10.10.30.115`); previously hosted on sugar. To upgrade module schema: `nix flake update brain && just deploy nero`. The vendored `modules/server/second-brain.nix` is kept on disk as a fallback during the soak window — delete it once nero has been stable for ≥24h.

## Gotchas
- Servers use `nixpkgs-unstable`, desktops use `nixos-25.05` (stable) — server modules get the latest NixOS options/packages
- `flake.lock` must NOT be in `.gitignore` — colmena needs it
- `just rebuild` runs `git add .` automatically before building
- Hyprpaper configs must NOT use quotes around file paths
- Server hosts use `mkServer` (no home-manager/stylix), desktops use `mkHost` — don't mix patterns
- spiders (VPS) is the only server with firewall enabled + nginx — all other servers use Caddy via psychosocial
