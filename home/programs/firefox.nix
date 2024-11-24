{ config, pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    # Основные настройки
    profiles.default = {
      id = 0;
      name = "Default";
      isDefault = true;

      # Настройки поведения
      settings = {
        "browser.download.dir" = "${config.home.homeDirectory}/Downloads";
        "browser.download.folderList" = 2;
        "browser.tabs.loadInBackground" = true;
        "browser.search.region" = "RU";
        "browser.search.isUS" = false;
        "distribution.searchplugins.defaultLocale" = "ru";
        "general.useragent.locale" = "ru";
        # Настройки для Bitwarden
        "extensions.bitwarden.environment" = "self-hosted";
        "extensions.bitwarden.server" = "https://vault.decard.rolder.app";
      };

      # Ставим расширения
      extensions = with pkgs.firefox-addons; [
        bitwarden
      ];

      extraConfig = ''
        // Отключаем автозаполнение
        user_pref("extensions.bitwarden.enableAutoFillOnPageLoad", false);
        user_pref("extensions.bitwarden.automaticFill", false);
        user_pref("extensions.bitwarden.enableAutofillCredentials", false);

        // Включаем PIN-код
        user_pref("extensions.bitwarden.enablePinLock", true);
        user_pref("extensions.bitwarden.pinLockOption", 0); // 0 = только при перезапуске
      '';
    };
  };
}
