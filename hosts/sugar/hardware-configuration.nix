{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  # Disk partitioning handled by disko (modules/server/disko.nix)
  # Default device: /dev/vda — override with server.disk if needed

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
