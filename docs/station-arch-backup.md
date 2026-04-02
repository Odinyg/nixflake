# Station → Arch Linux: Pre-Wipe Backup Checklist

## Overview

- **Purpose**: Back up all stateful data before wiping NixOS and installing Arch Linux on station
- **When to run**: BEFORE starting Arch installation — complete every section
- **Time estimate**: 30–60 minutes (plus Ollama model copy time if large)
- **Storage needed**: External drive or network storage with ≥100GB free
- **Backup destination**: Replace `/backup` below with your actual path (e.g., `/mnt/external/station-backup`)

---

## Section 1: Critical Keys (HIGH PRIORITY — without these, recovery is impossible)

### 1.1 SOPS Age Key — REQUIRED for home-manager secrets

The age key at this path decrypts all SOPS secrets (SSH keys, tokens, etc.).

```bash
# Backup
mkdir -p /backup/sops
cp -p ~/.config/sops/age/keys.txt /backup/sops/age-keys.txt

# Verify — should show AGE-SECRET-KEY-1... line
cat /backup/sops/age-keys.txt
```

- **Source path**: `/home/none/.config/sops/age/keys.txt`
- **Restore path**: `/home/none/.config/sops/age/keys.txt` (create dir first: `mkdir -p ~/.config/sops/age`)

---

### 1.2 SSH Private Keys

```bash
# Backup
mkdir -p /backup/ssh
cp -rp ~/.ssh/ /backup/ssh/

# List what was backed up
ls -la /backup/ssh/

# Verify fingerprints
for key in /backup/ssh/id_*; do ssh-keygen -l -f "$key" 2>/dev/null; done
```

- **Source path**: `~/.ssh/`
- **Restore path**: `~/.ssh/` (permissions: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*`)
- **Note**: `id_ed25519_sk` is managed by SOPS — it will be re-deployed by home-manager on first switch. Back it up anyway as a safety net.

---

### 1.3 SSH Host Keys — prevent MITM warnings on other machines

Other hosts (laptop, vnpc-21, servers) have station's host key fingerprint cached. Restoring these avoids re-verification prompts.

```bash
# Backup (run as root)
sudo mkdir -p /backup/ssh-host-keys
sudo cp -p /etc/ssh/ssh_host_* /backup/ssh-host-keys/

# Verify
ls -la /backup/ssh-host-keys/
```

- **Source path**: `/etc/ssh/ssh_host_*`
- **Restore path**: `/etc/ssh/` — restore BEFORE starting openssh for the first time on Arch

---

### 1.4 nix-serve Signing Key — REQUIRED to maintain binary cache for other hosts

Station serves a Nix binary cache at `http://station:5000`. Other hosts (laptop, vnpc-21) use it with public key `station:IH2kzUkYwmAVyk7J1XIgfIMw4d2vb5xA8ID8Ns9m7Xc=`. If the private key is lost, all other hosts must be reconfigured with a new key.

```bash
# Backup (run as root)
sudo mkdir -p /backup/nix-serve
sudo cp -p /var/lib/nix-serve/cache-priv-key.pem /backup/nix-serve/cache-priv-key.pem

# Verify — should be non-empty, starts with "-----BEGIN..."
sudo cat /backup/nix-serve/cache-priv-key.pem
```

- **Source path**: `/var/lib/nix-serve/cache-priv-key.pem`
- **Restore path**: `/var/lib/nix-serve/cache-priv-key.pem` (owner: `nix-serve` or `root`, mode `0600`)
- **Public key**: `station:IH2kzUkYwmAVyk7J1XIgfIMw4d2vb5xA8ID8Ns9m7Xc=`

---

## Section 2: Service State

### 2.1 Syncthing Identity — keep device ID to avoid re-pairing all devices

```bash
# Check sync is complete first — no pending items in web UI at http://localhost:8384
# Then backup
mkdir -p /backup/syncthing
cp -rp ~/.config/syncthing/ /backup/syncthing/

# Verify critical files exist
ls -la /backup/syncthing/cert.pem /backup/syncthing/key.pem
```

- **Source path**: `~/.config/syncthing/` (critical files: `cert.pem`, `key.pem`)
- **Restore path**: `~/.config/syncthing/` — restore BEFORE starting syncthing daemon

---

### 2.2 PostgreSQL Databases

Station has `postgresql.enable = true`. Check what databases exist before backing up.

```bash
# List databases
sudo -u postgres psql -c "\l"

# Full cluster dump (all databases + roles)
sudo -u postgres pg_dumpall > /backup/postgresql-$(date +%Y%m%d).sql

# Verify backup is non-empty
wc -l /backup/postgresql-$(date +%Y%m%d).sql
head -5 /backup/postgresql-$(date +%Y%m%d).sql
```

- **Restore after PostgreSQL on Arch**:
  ```bash
  sudo -u postgres psql < /backup/postgresql-YYYYMMDD.sql
  ```

---

### 2.3 Open WebUI Data

Station runs `hosted-services.open-webui.enable = true` (port 3000). Open WebUI stores user accounts, chat history, and model settings.

```bash
# Find Open WebUI data directory
sudo find /var/lib -name "open-webui" -type d 2>/dev/null
# Typically: /var/lib/open-webui/

# Backup
sudo mkdir -p /backup/open-webui
sudo cp -rp /var/lib/open-webui/ /backup/open-webui/

# Verify
ls -la /backup/open-webui/
```

- **Source path**: `/var/lib/open-webui/`
- **Restore path**: `/var/lib/open-webui/` — restore before starting open-webui service

---

### 2.4 Docker Volumes

```bash
# List all volumes
docker volume ls

# For each volume with data, find its mountpoint and back it up:
docker volume inspect <volume-name>  # shows Mountpoint path

# Backup each volume using a temporary container:
docker run --rm \
  -v <volume-name>:/data \
  -v /backup/docker-volumes:/backup \
  ubuntu tar czf /backup/<volume-name>.tar.gz /data

# Verify
tar tzf /backup/docker-volumes/<volume-name>.tar.gz | head -20
```

- **Restore**:
  ```bash
  docker volume create <volume-name>
  docker run --rm \
    -v <volume-name>:/data \
    -v /backup/docker-volumes:/backup \
    ubuntu tar xzf /backup/<volume-name>.tar.gz -C /
  ```

---

### 2.5 Ollama Models — potentially 10–100GB

```bash
# Check size first
du -sh /var/lib/ollama/models/ 2>/dev/null || du -sh ~/.ollama/models/ 2>/dev/null

# List models
ollama list

# Backup (use rsync for large transfers — resumable)
sudo rsync -av --progress /var/lib/ollama/models/ /backup/ollama-models/
# OR if user-local:
rsync -av --progress ~/.ollama/models/ /backup/ollama-models/

# Verify
ls -la /backup/ollama-models/
```

- **Source path**: `/var/lib/ollama/models/` (NixOS service default) or `~/.ollama/models/`
- **Restore path**: `/var/lib/ollama/models/` — restore before starting ollama service
- **Note**: Large — can sync from backup while using the system post-migration

---

## Section 3: Data Files

### 3.1 Home Directory Inventory

```bash
# Check what's in home that's NOT managed by dotfiles/syncthing
ls -la ~

# Check sizes of key directories
du -sh ~/Documents ~/Downloads ~/Projects ~/.local/share ~/.config 2>/dev/null

# Items to verify are synced or backed up:
# - ~/nixflake (this repo — push to remote first)
# - ~/Documents, ~/Downloads, ~/Projects
# - ~/.local/share/ (app data not managed by home-manager)
# - ~/.config/ (app configs not managed by home-manager)
```

---

### 3.2 Git Repositories — push all to remote

```bash
# Find all git repos under home (depth 4 to avoid deep nesting)
find ~ -name ".git" -maxdepth 4 -type d 2>/dev/null

# For each repo, check for unpushed commits:
git -C <repo-path> log @{u}..HEAD --oneline 2>/dev/null || echo "no remote configured"

# Push all pending commits before wiping
git -C <repo-path> push
```

---

### 3.3 GPG Keys (if any)

```bash
# Check if any secret keys exist
gpg --list-secret-keys

# If any exist, export them:
gpg --export-secret-keys --armor > /backup/gpg-secret-keys.asc
gpg --export --armor > /backup/gpg-public-keys.asc
gpg --export-ownertrust > /backup/gpg-ownertrust.txt

# Verify
wc -l /backup/gpg-secret-keys.asc
```

---

### 3.4 LM Studio Models

Station has `lmstudio.enable = true`. LM Studio stores models separately from Ollama.

```bash
# Find LM Studio model directory
ls -la ~/.cache/lm-studio/models/ 2>/dev/null || ls -la ~/.lmstudio/models/ 2>/dev/null

# Check size
du -sh ~/.cache/lm-studio/ 2>/dev/null

# Backup if present
rsync -av --progress ~/.cache/lm-studio/ /backup/lm-studio/
```

---

## Section 4: Cloud-Backed (no manual backup needed — just re-login after)

| Service | Action after Arch install |
|---------|--------------------------|
| ✅ 1Password | Re-login to app |
| ✅ Chromium/Zen Browser | Re-login — profiles sync via account |
| ✅ Tailscale | `tailscale up` |
| ✅ Netbird | `netbird up --management-url https://netbird.pytt.io` |
| ✅ Discord | Re-login |
| ✅ ProtonVPN | Re-login (station has `protonvpn.enable = true`) |

---

## Section 5: Backup Verification (DO THIS BEFORE WIPING)

Run all checks. Do not proceed if any fail.

```bash
# 1. Verify SOPS age key is present and has correct format
grep -c "AGE-SECRET-KEY" /backup/sops/age-keys.txt  # should print 1

# 2. Verify SSH keys backed up
ls -la /backup/ssh/

# 3. Verify SSH host keys backed up
ls -la /backup/ssh-host-keys/

# 4. Verify nix-serve key is non-empty
ls -la /backup/nix-serve/cache-priv-key.pem
wc -c /backup/nix-serve/cache-priv-key.pem  # should be > 0

# 5. Verify PostgreSQL backup is valid SQL
head -5 /backup/postgresql-*.sql  # should start with "-- PostgreSQL database cluster dump"
wc -l /backup/postgresql-*.sql    # should be non-zero

# 6. Verify Syncthing identity files
ls -la /backup/syncthing/cert.pem /backup/syncthing/key.pem

# 7. Verify nixflake repo is pushed
git -C ~/nixflake log @{u}..HEAD --oneline  # should be empty (nothing unpushed)

# 8. Spot-check Ollama models
ls /backup/ollama-models/ 2>/dev/null && echo "Ollama models backed up" || echo "WARNING: No Ollama backup"
```

---

## Section 6: Post-Migration Restore Order

Execute in this exact order after Arch base install + home-manager setup:

1. **SSH host keys** — copy to `/etc/ssh/` before starting openssh
   ```bash
   sudo cp /backup/ssh-host-keys/ssh_host_* /etc/ssh/
   sudo chmod 600 /etc/ssh/ssh_host_*_key
   sudo chmod 644 /etc/ssh/ssh_host_*_key.pub
   ```

2. **SOPS age key** — needed by home-manager on first switch
   ```bash
   mkdir -p ~/.config/sops/age
   cp /backup/sops/age-keys.txt ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

3. **SSH private keys** — needed for server access + git operations
   ```bash
   cp -rp /backup/ssh/ ~/.ssh/
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_*
   chmod 644 ~/.ssh/*.pub
   ```

4. **nix-serve signing key** — restore before starting nix-serve
   ```bash
   sudo mkdir -p /var/lib/nix-serve
   sudo cp /backup/nix-serve/cache-priv-key.pem /var/lib/nix-serve/cache-priv-key.pem
   sudo chmod 600 /var/lib/nix-serve/cache-priv-key.pem
   ```

5. **Syncthing identity** — restore before starting syncthing daemon
   ```bash
   mkdir -p ~/.config/syncthing
   cp /backup/syncthing/cert.pem /backup/syncthing/key.pem ~/.config/syncthing/
   chmod 600 ~/.config/syncthing/key.pem
   ```

6. **Run home-manager switch** — provisions dotfiles, tools, SSH keys from SOPS
   ```bash
   home-manager switch --flake .#none@station
   ```

7. **Start Syncthing** — files will sync from peers automatically

8. **Restore PostgreSQL**
   ```bash
   sudo -u postgres psql < /backup/postgresql-YYYYMMDD.sql
   ```

9. **Restore Open WebUI data**
   ```bash
   sudo cp -rp /backup/open-webui/ /var/lib/open-webui/
   ```

10. **Restore Docker volumes** — per-volume restore (see Section 2.3)

11. **Ollama models** — large, can sync from backup while using system
    ```bash
    sudo rsync -av /backup/ollama-models/ /var/lib/ollama/models/
    ```

12. **LM Studio models** — restore if backed up
    ```bash
    rsync -av /backup/lm-studio/ ~/.cache/lm-studio/
    ```

---

## Quick Reference: Key Paths

| Item | Source Path | Backup File |
|------|-------------|-------------|
| SOPS age key | `~/.config/sops/age/keys.txt` | `/backup/sops/age-keys.txt` |
| SSH keys | `~/.ssh/` | `/backup/ssh/` |
| SSH host keys | `/etc/ssh/ssh_host_*` | `/backup/ssh-host-keys/` |
| nix-serve key | `/var/lib/nix-serve/cache-priv-key.pem` | `/backup/nix-serve/cache-priv-key.pem` |
| Syncthing | `~/.config/syncthing/` | `/backup/syncthing/` |
| PostgreSQL | (pg_dumpall) | `/backup/postgresql-YYYYMMDD.sql` |
| Open WebUI | `/var/lib/open-webui/` | `/backup/open-webui/` |
| Ollama models | `/var/lib/ollama/models/` | `/backup/ollama-models/` |
| LM Studio | `~/.cache/lm-studio/` | `/backup/lm-studio/` |
| GPG keys | (gpg export) | `/backup/gpg-secret-keys.asc` |
