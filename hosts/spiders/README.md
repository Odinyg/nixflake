# spiders — Cantabo VPS

Network config is sourced from a sops secret (`eth0_network` in `secrets/spiders.yaml`)
rather than hardcoded in `default.nix`, so the public IP and topology stay encrypted.

## Adding / editing the network secret

Run `just secrets-spiders` and make sure the file contains an `eth0_network` key
with the full systemd-networkd `.network` file contents as a multi-line string:

```yaml
eth0_network: |
  [Match]
  Name=eth0

  [Network]
  Address=95.111.255.104/20
  Address=2a02:c207:2318:6493::1/64
  Gateway=95.111.240.1
  DNS=213.136.95.10
  DNS=213.136.95.11
  DNS=2a02:c207::1:53
  IPv6AcceptRA=no

  [Route]
  Gateway=fe80::1
  GatewayOnLink=yes
```

## Verifying before deploy

```sh
# 1. Build (no apply) — catches config errors
nix shell nixpkgs#colmena -c colmena build --on spiders

# 2. Render the secret locally to sanity-check the .network syntax
sops -d secrets/spiders.yaml | yq -r .eth0_network
```

## Deploy risk

This host switches from scripted networking to systemd-networkd. A malformed
`.network` template means spiders comes up without networking and is unreachable
over SSH — you'll need console access via the Cantabo web UI to recover.
Always `colmena build` before `colmena apply` for this host.
