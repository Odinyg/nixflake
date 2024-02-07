{ ... }: {
  imports = [
    ./tailscale.nix
    ./work.nix
    ./password.nix
    ./crypt.nix
    ./crypt.nix
    ./syncthing.nix

  ];
}
