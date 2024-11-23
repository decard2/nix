{ config, pkgs, ... }: {
  time.timeZone = "Asia/Irkutsk";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8" ];
}
