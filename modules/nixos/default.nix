{ ... }: {
  imports = [
    ./tailscale.nix
    ./virt-man.nix
    ./work.nix
    ./password.nix
    ./crypt.nix
    ./hardware
    ./fonts.nix
    ./syncthing.nix
    ./polkit.nix
    ./greetd.nix
    ./anbox.nix

  ];
}
