# parts/ — Flake-Parts Modules

This directory contains [flake-parts](https://flake.parts) modules that compose the flake outputs.

## Files

| File | Purpose |
|------|---------|
| `lib.nix` | Shared helpers — `hostModules`, `pkgs-unstable`, `commonModules`. Imported by both `hosts.nix` and `deploy.nix`. |
| `hosts.nix` | `mkHost` helper + all `nixosConfigurations` |
| `dev.nix` | `perSystem` config — formatter (`nixfmt-rfc-style`) |
| `deploy.nix` | Colmena multi-host deployment configuration |

## Adding a New Host

1. Create the host directory under `hosts/<name>/` with `default.nix` and `hardware-configuration.nix`
2. Add an entry in `hosts.nix`:
   ```nix
   new-host = mkHost {
     hostPath = ../hosts/new-host;
     user = "username";
     # extraModules = [ ];  # optional, e.g. nixos-hardware modules
   };
   ```
3. Add a matching entry in `deploy.nix`:
   ```nix
   new-host = mkColmenaHost {
     hostPath = ../hosts/new-host;
     user = "username";
     targetHost = "new-host";  # hostname or IP reachable via Tailscale/SSH
   };
   ```
4. Run `just rebuild` to verify

## How It Works

`flake.nix` calls `flake-parts.lib.mkFlake` and imports all modules from this directory. Each module can define:

- **`flake.*`** — Top-level flake outputs (nixosConfigurations, colmena, etc.)
- **`perSystem`** — Per-system outputs (formatter, devShells, packages, etc.)

The `lib.nix` file is a plain Nix function (not a flake-parts module) that provides the shared `hostModules` function used by both `hosts.nix` and `deploy.nix`, ensuring host module lists never drift apart.
