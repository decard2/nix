{ lib, ... }:

{
  # Создаем desktop файл для Bridge
  xdg.desktopEntries.bridge = {
    name = "The Bridge";
    exec = "/home/decard/projects/rolder/bridge/src-tauri/target/release/bridge";
    icon = "/home/decard/projects/rolder/bridge/src-tauri/icons/128x128.png";
    categories = [
      "Development"
      "Utility"
    ];
    terminal = false;
  };

  # Добавляем symlink в ~/.local/bin для быстрого доступа из командной строки
  home.activation.linkBridge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.local/bin
    ln -sf /home/decard/projects/rolder/bridge/src-tauri/target/release/bridge $HOME/.local/bin/bridge
  '';
}
