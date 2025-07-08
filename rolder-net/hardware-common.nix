# Common hardware configuration for all hosts
# This file contains shared hardware settings for KVM/QEMU VMs
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Common kernel modules for all VMs
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "virtio_ring"
  ];

  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_rng"
  ];

  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Network interface configuration
  # All VMs use ens3 interface by default in KVM/QEMU
  networking.useDHCP = lib.mkDefault false;
  networking.interfaces.ens3.useDHCP = lib.mkDefault false;

  # Platform configuration
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Console configuration for VirtIO
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200"
    "earlyprintk=ttyS0,115200"
    "consoleblank=0"
  ];

  # Boot loader - GRUB for BIOS Legacy boot
  boot.loader.grub.enable = true;
  # Device configuration handled by disko
}
