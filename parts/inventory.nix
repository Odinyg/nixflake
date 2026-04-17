# Centralized IP registry — single source of truth for all host IPs.
# Import with: inventory = import ./inventory.nix;
{
  # Managed NixOS servers
  psychosocial = "10.10.30.110";
  sugar = "10.10.30.111";
  pulse = "10.10.30.112";
  nero = "10.10.30.115";
  byob = "10.10.50.110";
  spiders = "netbird.pytt.io"; # Public VPS — DNS name

  # External infrastructure (not managed by this flake)
  truenas = "10.10.10.20";
  pve1 = "10.10.10.227";
  pve2 = "10.10.10.228";
  jellyfin = "10.10.10.20"; # TrueNAS k8s (port 30013 stays in Caddy config)
  openwebui = "10.10.10.10";
  ollama = "10.10.10.163";
  craftbeerpi = "10.10.20.174";
  homeassistant = "10.10.20.205";
}
