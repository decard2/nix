{ config, pkgs, ... }:
{
 /*  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.guest.enable = true;
  users.extraGroups.vboxusers.members = [ "decard" ];
 */
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    virtiofsd
  ];
  programs.virt-manager.enable = true;
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
  users.users.decard.extraGroups = [ "libvirtd" ];
}
