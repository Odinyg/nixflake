{ ... }:
{
  imports = [
    ./tailscale.nix
    ./onedrive.nix
    ./gaming.nix
    ./work.nix
    ./password.nix
    ./crypt.nix
    ./hardware
    ./fonts.nix
    ./syncthing.nix
    ./polkit.nix
    ./greetd.nix
    ./sunshine.nix
    ./general.nix
    ./password.nix
    ./ollama.nix
    ./styling.nix
    ./hyprland.nix
    ./virtualization.nix
    #  ./secrets.nix
  ];
}
