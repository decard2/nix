{ config, lib, ... }:
{
  xdg.configFile."mimeapps.list" = lib.mkIf config.xdg.mimeApps.enable { force = true; };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "thunar.desktop";
      "application/x-gnome-saved-search" = "thunar.desktop";

      "application/json" = "dev.zed.Zed.desktop";

      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "x-scheme-handler/http" = "yandex-browser-stable.desktop";
      "x-scheme-handler/https" = "yandex-browser-stable.desktop";
      "x-scheme-handler/chrome" = "yandex-browser-stable.desktop";
      "text/html" = "yandex-browser-stable.desktop";
      "application/x-extension-htm" = "yandex-browser-stable.desktop";
      "application/x-extension-html" = "yandex-browser-stable.desktop";
      "application/x-extension-shtml" = "yandex-browser-stable.desktop";
      "application/xhtml+xml" = "yandex-browser-stable.desktop";
      "application/x-extension-xhtml" = "yandex-browser-stable.desktop";
      "application/x-extension-xht" = "yandex-browser-stable.desktop";
      "application/pdf" = "yandex-browser-stable.desktop";
      "image/jpeg" = "yandex-browser-stable.desktop";
      "image/png" = "yandex-browser-stable.desktop";
      "image/gif" = "yandex-browser-stable.desktop";
      "image/webp" = "yandex-browser-stable.desktop";
      "image/svg+xml" = "yandex-browser-stable.desktop";
      "image/avif" = "yandex-browser-stable.desktop";
    };
  };
}
