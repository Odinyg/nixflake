{ ... }: {
  imports = [
    ./tailscale.nix
    ./work.nix
    ./password.nix
    ./crypt.nix
    ./hardware
    ./fonts.nix
    ./syncthing.nix

  ];
}
