---
name: server-add-secrets
description: Generate and add secrets to SOPS-encrypted YAML files for a NixOS server service
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: opus
argument-hint: <service-name> [host]
---

# Add secrets for a server service

Generate secrets and add them to encrypted `secrets/<host>.yaml`.

## Step 1: Parse arguments

Parse `$ARGUMENTS` for service name and optional host. Ask if service name is missing.

## Step 2: Discover required secrets

Try in order:

1. **Plan file** — `plans/<service>.md` or `plans/archive/<service>.md`. Extract secrets from REMINDER section and `sops.secrets.*` / `sops.placeholder.*` refs. Read host from plan header.
2. **Module** — `modules/server/<service>.nix`. Extract `sops.secrets.<name>`, `config.sops.placeholder.<name>`, `sops.templates."<name>"`. Find host via `grep -l "server.<service>" hosts/*/default.nix`.
3. **Host config** — `hosts/<host>/default.nix`, scan for sops refs related to the service.

## Step 3: Categorize each secret

| Pattern | Method |
|---------|--------|
| `*encryption_key*`, `*master_key*`, `*jwt_secret*`, `*session_secret*`, `*signing_key*`, `*secret_key*` | `openssl rand -hex 32` |
| `*_pass`, `*_password`, `postgresql_*_password` | `openssl rand -base64 32` |
| `*_api_key*` | `openssl rand -hex 24` |
| `*oidc_client_secret*` | Special: `nix-shell -p authelia --run "authelia crypto hash generate pbkdf2 --variant sha512 --random"` — store plaintext in SOPS, show digest hash for `modules/server/authelia.nix` |
| External API keys, tokens, URLs | Ask the user |

## Step 4: Check existing secrets

```bash
sops -d secrets/<host>.yaml 2>/dev/null | grep -E '^(secret_names):' || true
```

Skip existing secrets unless user asks to regenerate.

## Step 5: Generate, collect, and write

1. Auto-generate applicable secrets
2. Generate OIDC secrets via authelia CLI
3. Ask user for external values
4. Write each with `sops --set '["<name>"] "<value>"' secrets/<host>.yaml`

If the file doesn't exist: `sops -e /dev/null > secrets/<host>.yaml` first.

## Step 6: Summary

Show: secrets added (with generation method), OIDC digest hashes (if any), and next steps (`sops secrets/<host>.yaml` to verify, `colmena apply --on <host>` to deploy).
