{ ... }: {
  imports = [
    ./tailscale.nix
    ./virt-man.nix
    ./work.nix
    ./virtualbox.nix
    ./password.nix
    ./crypt.nix
    ./hardware
    ./fonts.nix
    ./syncthing.nix
    ./polkit.nix

  ];
}
