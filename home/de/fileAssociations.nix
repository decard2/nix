{ config, lib, ... }:
let
  browser = "yandex-browser.desktop";
in
{
  xdg.configFile."mimeapps.list" = lib.mkIf config.xdg.mimeApps.enable { force = true; };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "thunar.desktop";
      "application/x-gnome-saved-search" = "thunar.desktop";

      "application/json" = "dev.zed.Zed.desktop";
      "text/javascript" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";

      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";

      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/yabrowser" = browser;
      "x-scheme-handler/chrome" = browser;
      "text/html" = browser;
      "text/xml" = browser;
      "application/x-extension-htm" = browser;
      "application/x-extension-html" = browser;
      "application/x-extension-shtml" = browser;
      "application/xhtml+xml" = browser;
      "application/x-extension-xhtml" = browser;
      "application/x-extension-xht" = browser;
      "application/pdf" = browser;
      "application/xml" = browser;
      "application/rdf+xml" = browser;
      "application/rss+xml" = browser;
      "image/jpeg" = browser;
      "image/png" = browser;
      "image/gif" = browser;
      "image/webp" = browser;
      "image/svg+xml" = browser;
      "image/avif" = browser;

      # Office documents — Yandex Browser открывает их встроенно
      "application/msword" = browser;
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = browser;
      "application/vnd.ms-excel" = browser;
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = browser;
      "application/vnd.ms-powerpoint" = browser;
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = browser;
      "application/vnd.oasis.opendocument.text" = browser;
      "application/vnd.oasis.opendocument.spreadsheet" = browser;
      "application/vnd.oasis.opendocument.presentation" = browser;
      "application/rtf" = browser;
      "text/csv" = browser;
    };
  };
}
