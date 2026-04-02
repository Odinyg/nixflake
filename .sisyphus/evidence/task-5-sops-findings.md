# Task 5 — sops-nix standalone Home Manager validation

## Scope
- Validate whether `inputs.sops-nix.homeManagerModules.sops` evaluates in standalone HM mode.
- Determine secret paths used in standalone HM mode.
- Identify HM modules using `/run/secrets/*` that require updates.

## Evidence produced
- Eval output: `.sisyphus/evidence/task-5-sops-standalone.txt`
- `/run/secrets` references: `.sisyphus/evidence/task-5-sops-paths.txt`

## Validation result
**Result: YES, the standalone HM sops module evaluates successfully.**

Command run:
```bash
nix eval .#homeConfigurations."none@station".activationPackage.drvPath
```

Observed output:
```text
"/nix/store/npv6nzcis6qg4lgvr2allw3knjkvw7ph-home-manager-generation.drv"
```

## Secret path behavior in standalone HM mode

### What the module source says
From `Mic92/sops-nix` `modules/home-manager/sops.nix`:
- `sops.defaultSymlinkPath` default is:
  - `${config.xdg.configHome}/sops-nix/secrets`
- `sops.defaultSecretsMountPoint` default is:
  - `%r/secrets.d` (`%r` resolves to `$XDG_RUNTIME_DIR` on Linux)
- Per-secret default `path` is:
  - `${cfg.defaultSymlinkPath}/${name}`

### What this flake eval returns
```bash
nix eval --json .#homeConfigurations."none@station".options.sops.defaultSymlinkPath.default
nix eval --json .#homeConfigurations."none@station".options.sops.defaultSecretsMountPoint.default
```

Outputs:
- `"/home/none/.config/sops-nix/secrets"`
- `"%r/secrets.d"`

### Conclusion on paths
- Standalone HM **does not default to** `/run/secrets/*`.
- Runtime decrypted generations live under `%r/secrets.d` (Linux: runtime dir, typically `/run/user/<uid>/secrets.d`).
- Canonical per-secret consumer path is the symlink path:
  - `/home/none/.config/sops-nix/secrets/<secret-name>` (with current defaults)

## HM modules referencing `/run/secrets/*`
From `.sisyphus/evidence/task-5-sops-paths.txt`:

1. `modules/home-manager/cli/mcp.nix`
   - `/run/secrets/github_token` (2 occurrences)

No other `/run/secrets` references were found under `modules/home-manager/**/*.nix`.

## What needs updating
- `modules/home-manager/cli/mcp.nix` should stop hardcoding `/run/secrets/github_token`.
- Recommended HM-safe reference pattern:
  - Use `config.sops.secrets.github_token.path` (preferred), or
  - derive from `config.sops.defaultSymlinkPath` if needed.

## Recommended Task 17 pattern (standalone `home.nix`)
Use this baseline in standalone HM:

```nix
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "/home/none/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    validateSopsFiles = false;

    # Declare explicit secrets used by HM modules
    secrets.github_token = { };
  };
}
```

And in consumers (e.g. MCP module), reference:
```nix
config.sops.secrets.github_token.path
```

This keeps modules compatible with standalone HM path semantics and avoids `/run/secrets` assumptions.
