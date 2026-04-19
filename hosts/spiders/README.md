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
  Address=<IPv4>/<prefix>
  Address=<IPv6>/<prefix>
  Gateway=<IPv4 gateway>
  DNS=<DNS1>
  DNS=<DNS2>
  DNS=<DNS3>
  IPv6AcceptRA=no

  [Route]
  Gateway=fe80::1
  GatewayOnLink=yes
```

Fill in the actual values from your VPS provider's control panel.

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
