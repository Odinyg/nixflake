{ ... }: {
  imports = [
    ./tailscale.nix
    ./virutalbox.nix
    ./work.nix
    ./password.nix
    ./crypt.nix
    ./hardware
    ./fonts.nix
    ./syncthing.nix
    ./polkit.nix

  ];
}
