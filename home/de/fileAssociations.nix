{ config, lib, ... }:
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
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/chrome" = "google-chrome.desktop";
      "text/html" = "google-chrome.desktop";
      "application/x-extension-htm" = "google-chrome.desktop";
      "application/x-extension-html" = "google-chrome.desktop";
      "application/x-extension-shtml" = "google-chrome.desktop";
      "application/xhtml+xml" = "google-chrome.desktop";
      "application/x-extension-xhtml" = "google-chrome.desktop";
      "application/x-extension-xht" = "google-chrome.desktop";
      "application/pdf" = "google-chrome.desktop";
      "image/jpeg" = "google-chrome.desktop";
      "image/png" = "google-chrome.desktop";
      "image/gif" = "google-chrome.desktop";
      "image/webp" = "google-chrome.desktop";
      "image/svg+xml" = "google-chrome.desktop";
      "image/avif" = "google-chrome.desktop";
    };
  };
}
