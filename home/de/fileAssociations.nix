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
      "x-scheme-handler/http" = "yandex-browser.desktop";
      "x-scheme-handler/https" = "yandex-browser.desktop";
      "x-scheme-handler/chrome" = "yandex-browser.desktop";
      "text/html" = "yandex-browser.desktop";
      "application/x-extension-htm" = "yandex-browser.desktop";
      "application/x-extension-html" = "yandex-browser.desktop";
      "application/x-extension-shtml" = "yandex-browser.desktop";
      "application/xhtml+xml" = "yandex-browser.desktop";
      "application/x-extension-xhtml" = "yandex-browser.desktop";
      "application/x-extension-xht" = "yandex-browser.desktop";
      "application/pdf" = "yandex-browser.desktop";
      "image/jpeg" = "yandex-browser.desktop";
      "image/png" = "yandex-browser.desktop";
      "image/gif" = "yandex-browser.desktop";
      "image/webp" = "yandex-browser.desktop";
      "image/svg+xml" = "yandex-browser.desktop";
      "image/avif" = "yandex-browser.desktop";
    };
  };
}
