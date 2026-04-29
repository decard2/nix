{ pkgs, ... }:
{
  # pcscd на хосте намеренно НЕ включаем: он бы попытался claim'ить
  # Rutoken по libccid и постоянно отваливался по LIBUSB_ERROR_ACCESS,
  # что заставляет токен моргать и блокирует контейнер.
  # Все криптооперации делает pcscd/КриптоПро внутри distrobox-контейнера.

  environment.systemPackages = with pkgs; [
    pcsc-tools
    opensc
  ];

  # Aktiv Co. — Rutoken family (Lite/S/ECP/etc.).
  # MODE=0666 нужно потому, что pcscd внутри distrobox запускается под
  # mapped-root (subuid ~100000), и `uaccess`-ACL для UID 1000 ему не
  # помогает. Безопасно: токен физически подключён к этой машине.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0a89", MODE="0666"
  '';
}
