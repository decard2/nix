{ pkgs, ... }: {
  home.packages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    win-virtio
    swtpm
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
