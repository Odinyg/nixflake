# Station on Arch Linux — Nix remote builder + binary cache server

## 1) Overview

`station` acts as the shared distributed build node and binary cache for other hosts (notably `laptop` and `VNPC-21`).

- Cache URL used by clients: `http://station:5000`
- Cache public key used by clients: `station:IH2kzUkYwmAVyk7J1XIgfIMw4d2vb5xA8ID8Ns9m7Xc=`
- Station static IP is expected to remain `10.10.10.10` on LAN

This role has two separate components:

1. **nix-daemon**: performs builds (including remote builder workloads)
2. **nix-serve**: exposes built store paths over HTTP as a binary cache

---

## 2) Nix Daemon Configuration

### nix.conf

Configure `/etc/nix/nix.conf` with:

```ini
experimental-features = nix-command flakes
trusted-users = root none
max-jobs = auto
cores = 0
```

### Enable daemon

```bash
sudo systemctl enable --now nix-daemon
```

### Verify

```bash
nix --version
```

---

## 3) nix-serve Binary Cache

Install `nix-serve` on station:

```bash
nix profile install nixpkgs#nix-serve
```

(Alternative: manage it via Home Manager if preferred.)

### Signing key (critical)

Before/while migrating from NixOS station, recover the **existing private signing key** so clients continue trusting cache signatures.

```bash
# On current NixOS station, find the key:
sudo cat /var/lib/nix-serve/cache-priv-key.pem 2>/dev/null || \
sudo cat /etc/nix/secret-key-file 2>/dev/null || \
sudo find /etc /var/lib -name "*secret*key*" 2>/dev/null
```

Expected public key remains:

```text
station:IH2kzUkYwmAVyk7J1XIgfIMw4d2vb5xA8ID8Ns9m7Xc=
```

Restore private key to:

```text
/var/lib/nix-serve/cache-priv-key.pem
```

### systemd service

Create `/etc/systemd/system/nix-serve.service`:

```ini
[Unit]
Description=Nix binary cache server
After=network.target

[Service]
Type=simple
User=nobody
Group=nobody
ExecStart=/run/current-system/sw/bin/nix-serve --listen 0.0.0.0:5000 --secret-key-file /var/lib/nix-serve/cache-priv-key.pem
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

> On Arch, if `/run/current-system/sw/bin/nix-serve` is unavailable, replace `ExecStart` with the actual path (for example the profile path under `/nix/var/nix/profiles/default/bin/nix-serve`).

Enable and verify:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nix-serve
curl http://localhost:5000/nix-cache-info
```

---

## 4) Firewall

Allow TCP/5000 from LAN clients (10.10.10.0/24).

```bash
# Using iptables or nftables
# Or simply ensure no firewall blocks port 5000 on the LAN interface
```

---

## 5) Garbage Collection

NixOS previously handled GC automatically (weekly, removing generations older than 14 days). Recreate that behavior on Arch with systemd.

Create `/etc/systemd/system/nix-gc.service`:

```ini
[Unit]
Description=Nix garbage collection

[Service]
Type=oneshot
ExecStart=/usr/bin/nix-collect-garbage --delete-older-than 14d
```

Create `/etc/systemd/system/nix-gc.timer`:

```ini
[Unit]
Description=Weekly Nix garbage collection

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

Enable timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nix-gc.timer
```

---

## 6) Remote Builder Configuration

Station can serve as an SSH remote builder in addition to serving cache artifacts.

Add to `/etc/nix/nix.conf` on client machines that should offload builds:

```ini
builders = ssh://none@station x86_64-linux - 8 1 kvm,nixos-test,big-parallel,benchmark
```

Ensure passwordless SSH key authentication works from each client host to `none@station`.

---

## 7) Client Configuration (Other Hosts)

`laptop` and `VNPC-21` are already configured to trust station’s cache key and use station for distributed build flow.

- If station stays at `10.10.10.10`, no client config changes are needed.
- If station IP/hostname changes, update:
  - `hosts/laptop/default.nix`
  - `hosts/vnpc-21/default.nix`

Client-side connectivity check:

```bash
curl http://station:5000/nix-cache-info
```

---

## 8) Verification

Run on **station**:

```bash
systemctl status nix-daemon
systemctl status nix-serve
curl http://localhost:5000/nix-cache-info
```

Run from **another host**:

```bash
curl http://station:5000/nix-cache-info
```

Expected response includes:

```text
StoreDir: /nix/store
WantMassQuery: 1
Priority: 30
```
