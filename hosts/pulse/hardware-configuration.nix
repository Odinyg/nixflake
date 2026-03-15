{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];

  # Disk partitioning handled by disko (modules/server/disko.nix)
  # Default device: /dev/vda — override with server.disk if needed

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
