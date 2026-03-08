---
name: server-add-secrets
description: Generate and add secrets to SOPS-encrypted YAML files for a NixOS server service
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
model: sonnet
argument-hint: <service-name>
---

# Add secrets for a server service

Parse the service's plan file, auto-generate secrets, ask for non-generatable values, and add everything to the encrypted `secrets/<host>.yaml`.

## Step 1: Parse arguments

Parse `$ARGUMENTS` for the service name (e.g. `/server-add-secrets grafana`). If missing, list plan files in `plans/` and `plans/archive/` and ask.

## Step 2: Find and read the plan

Look for the plan file in order:
1. `plans/<service>.md`
2. `plans/archive/<service>.md`

If not found, stop and tell the user to run `/server-plan-service` first.

Read the plan file. Verify `**Status:** plan-complete` is present.

## Step 3: Determine the target host

Read the `**Host:** <host>` line from the plan header.

Map host to SOPS tier and key:

| Host | Tier | SOPS key anchor |
|------|------|-----------------|
| psychosocial | critical | `&homelab_critical` |
| byob | low | `&homelab_low` |
| sugar | general | `&homelab_general` |
| pulse | general | `&homelab_general` |

## Step 4: Extract secrets from the plan

Find the `secrets/<host>.yaml` REMINDER section in the Implementation Plan. This lists the secrets to add.

Also check `sops.secrets.*` and `sops.templates.*` references in the host config changes — each `sops.placeholder.<name>` or `sops.secrets.<name>` needs a corresponding key in the YAML.

Build a list of `(secret_name, description)` pairs.

## Step 5: Categorize each secret

### Category A: Auto-generate
Secret names matching these patterns:

| Pattern | Generation method |
|---------|-------------------|
| `*encryption_key*`, `*master_key*`, `*jwt_secret*`, `*session_secret*`, `*auth_secret*` | `openssl rand -hex 32` (64 hex chars) |
| `*secret*` (catch-all) | `openssl rand -hex 24` (48 hex chars) |
| `*_pass`, `*_password` | `openssl rand -hex 16` (32 hex chars) |

### Category B: Ask the user
- API keys, tokens from external services
- OIDC client IDs (these come from Authelia config)
- Email addresses
- Anything that can't be auto-generated

## Step 6: Generate and collect values

1. **Auto-generate** all Category A values using Bash `openssl rand -hex N`.
2. **Ask the user** for all Category B values.

Show a summary before asking:

```
Auto-generated:
  grafana_admin_password = (random 32-char hex)
  grafana_oauth_client_secret = (random 48-char hex)

Need your input:
  grafana_oauth_client_id = ?
```

## Step 7: Write to secrets/<host>.yaml (SOPS cycle)

### 7a: Check if file exists

```bash
test -f secrets/<host>.yaml && echo "exists" || echo "new"
```

### 7b: Decrypt (if exists)

```bash
sops -d secrets/<host>.yaml > /tmp/sops-decrypted-<host>.yaml
```

If decryption fails, check if age keys are available. The key file location depends on the host — check `.sops.yaml` for the key reference.

### 7c: Check for duplicates

Read the decrypted file. For each secret to add, check if the key already exists. If it does:
- Warn the user: `"grafana_admin_password already exists — skipping"`
- Skip that secret

### 7d: Append new secrets

Add to the YAML (or create new file):

```yaml
# <ServiceName>
secret_name_1: value1
secret_name_2: value2
```

### 7e: Encrypt

```bash
sops -e -i secrets/<host>.yaml
```

### 7f: Cleanup

```bash
rm -f /tmp/sops-decrypted-<host>.yaml
```

## Step 8: Summary

Show the user:

**Secrets added to `secrets/<host>.yaml`:**
- `secret_name` — auto-generated / user-provided

**Next steps:**
- Verify with `sops secrets/<host>.yaml` (opens decrypted in editor)
- If the service needs a database: `/server-create-db <service>`
- Deploy: `colmena apply --on <host>`
