{ ... }:
{
  imports = [
    ./tailscale.nix
    ./onedrive.nix
    ./virt-man.nix
    ./docker.nix
    ./work.nix
    ./dwm.nix
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
  ];
  docker.enable = true;
}
