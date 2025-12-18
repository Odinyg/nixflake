{ ... }:
{
  imports = [
    ./tailscale.nix
    ./onedrive.nix
    ./gaming.nix
    ./work
    ./password.nix
    ./crypt.nix
    ./hardware
    ./fonts.nix
    ./syncthing.nix
    ./polkit.nix
    ./greetd.nix
    ./sunshine.nix
    ./general.nix
    ./ollama.nix
    ./styling.nix
    ./hyprland.nix
    ./cosmic.nix
    ./virtualization.nix
    ./security.nix
    ./distributed-builds.nix
    ./init-net.nix
    ./hosted-services
    ./secrets.nix
  ];
}
