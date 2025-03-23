{ pkgs, ... }:
{
  services = {
    gvfs.enable = true;
    udisks2.enable = true;
  };
  environment.systemPackages = with pkgs; [
    # udiskie
    usbutils
    # android-udev-rules
    # gvfs
    # jmtpfs
  ];
}
