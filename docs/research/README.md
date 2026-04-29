# Research

Исследовательские документы. Не реализация — анализ подходов с примерами и ссылками
на источники. Перед тем как делать что-то крупное в этих темах — стоит читать.

## Документы

- **[Yandex.Browser в NixOS — декларативная конфигурация](./yandex-browser-nixos.md)**
  Как полностью декларативно управлять Yandex.Browser: установка, расширения,
  настройки, browser-policies, NativeMessagingHosts, профиль. Эмпирически
  установлено через `strings` бинаря, какие пути и механизмы работают.

- **[Нативная упаковка КриптоПро / Контура для NixOS](./cryptopro-kontur-native-packaging.md)**
  Как собрать КриптоПро CSP, Cades Browser Plug-in, Контур.Плагин, Диаг.Плагин
  как обычные nix-пакеты — без distrobox. Подход autoPatchelfHook + tmpfiles +
  Native Messaging, со ссылками на готовые community-референсы (sakost, SomeoneSerge).
