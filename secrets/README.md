# Secrets Management with sops-nix

This directory contains encrypted secrets managed by sops-nix.

## Setup

### 1. Generate Age Key (if not already done)

The age key for sops is stored at `/var/lib/sops-nix/key.txt` on each host.

To generate a new key for a host:
```bash
sudo mkdir -p /var/lib/sops-nix
sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key | sudo tee /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
```

To get the public key (to add to `.sops.yaml`):
```bash
sudo ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

### 2. Update `.sops.yaml`

Add the new host's public age key to `.sops.yaml`:
```yaml
keys:
  - &laptop age1xxx...
  - &station age1yyy...
  - &vnpc21 age1zzz...
  - &newhost age1abc...  # Add your new host key here

creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - age:
          - *laptop
          - *vnpc21
          - *station
          - *newhost  # Add your new host here
```

### 3. Re-encrypt Secrets

After adding a new host key, re-encrypt all secrets:
```bash
cd /home/odin/nixflake
sops updatekeys secrets/secrets.yaml
```

## Usage

### Enable Secrets in Your Host

Add to your host configuration (e.g., `profiles/base.nix`):
```nix
secrets.enable = true;
```

### Add New Secrets

Edit the encrypted file:
```bash
sops secrets/secrets.yaml
```

Add your secrets in the format:
```yaml
ssh_keys:
  personal_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----

smb:
  username: myusername
  password: mypassword
```

### Use Secrets in NixOS Configuration

In `modules/nixos/secrets.nix`, add the secret definition:
```nix
sops.secrets."smb/username" = {
  owner = "root";
};

sops.secrets."smb/password" = {
  owner = "root";
  mode = "0600";
};
```

Then reference it in your configuration:
```nix
# Example: In nas.nix
options = [
  "username=\${config.sops.secrets."smb/username".path}"
  "password=\${config.sops.secrets."smb/password".path}"
];
```

### Current Secrets

The following secrets are currently configured:
- `ssh_keys/personal_key` → `/home/${user}/.ssh/id_personal`
- `ssh_keys/work_key` → `/home/${user}/.ssh/id_work`
- `ssh_public_keys/personal_key` → `/home/${user}/.ssh/id_personal.pub`
- `ssh_public_keys/work_key` → `/home/${user}/.ssh/id_work.pub`

## Troubleshooting

### Check if secrets are being decrypted

```bash
ls -la /run/secrets/
```

### View secret paths
```bash
nix eval .#nixosConfigurations.VNPC-21.config.sops.secrets --apply 'x: builtins.attrNames x'
```

### Check age key

```bash
sudo cat /var/lib/sops-nix/key.txt
```
