{ pkgs, ... }:
{
  home.packages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    virtio-win
    swtpm
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
