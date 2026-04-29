# Yandex.Browser в NixOS — декларативная конфигурация

Исследование (не код): как полностью декларативно управлять Yandex.Browser
26.3.1.1088 на NixOS 25.x — пакет, расширения, политики, NativeMessagingHosts,
дефолты браузера.

## TL;DR

1. **Пакет.** Оставить `inputs.yandex-browser` от `miuirussia/yandex-browser.nix` —
   он жив (последний автообновляющийся коммит **2026-04-09**) и обновляется. Альтернатива
   `teu5us/nix-yandex-browser` **архивирована 2026-03-29** и устарела.
   `extensions`-параметр у `miuirussia` объявлен, но не используется (dead-stub) —
   override через `.override { extensions = […]; }` ничего не сделает.

2. **Расширения.** В Yandex.Browser `ExtensionInstallForcelist` /
   `force_install` в `ExtensionSettings` **запрещены политикой безопасности**
   (см. примечания «Browser ограничивает установку расширений…» в офдоках).
   Рабочий nix-way — **external-extensions механизм Chromium**:
   класть JSON-файл `<id>.json` с `external_update_url` (или `external_crx`+`external_version`)
   в каталог `Extensions/` рядом с бинарём. Это та же техника, которой пользуется
   home-manager `programs.chromium.extensions` для Chromium/Brave/Vivaldi и сама
   Яндекс пользуется для своего расширения «Коллекции».

3. **Политики браузера.** Yandex.Browser читает `/etc/opt/yandex/browser/policies/managed/*.json`
   (подтверждено `strings` бинарника + офдоки). Файлы system-wide,
   управляются через `environment.etc.*` (NixOS-модуль), не через home-manager.
   Yandex понимает весь набор Chromium policies + ~100 своих `Yandex*`-политик
   (Adblock, NTP, Login, DownloadRestrictions, и т. п.).

4. **NativeMessagingHosts.** Bridge-манифесты сейчас лежат в
   `~/.config/yandex-browser/NativeMessagingHosts/` (user-level). Декларативный
   путь: либо `home.file.".config/yandex-browser/NativeMessagingHosts/<name>.json"`,
   либо `environment.etc."chromium/native-messaging-hosts/<name>.json"` —
   **этот системный путь Yandex.Browser явно ищет** (подтверждено по `strings`).

5. **Расширения с API-ключом / настройками.** `ExtensionSettings`-policy в Yandex
   присутствует как имя, но `force_install` и любые попытки назначать
   расширению поведение через политики могут игнорироваться. Безопасный путь —
   класть `external_update_url` для установки и не трогать настройки расширения.
   Настройки большинства реальных расширений (CryptoPro Cades, Контур.Плагин)
   управляются не через ExtensionSettings, а через `chrome.storage.managed`
   полем `3rdparty.extensions[<id>]` в policy JSON.

## Текущее состояние репо

```
flake.nix                              inputs.yandex-browser → github:miuirussia/yandex-browser.nix
home/programs/yandex-browser.nix       home.packages = [ inputs.yandex-browser.packages.…stable ]
~/.config/yandex-browser/NativeMessagingHosts/
  ├ ru.cryptopro.nmcades.json     ←  руками
  ├ kd.nc.json                    ←  руками
  └ kontur.plugin.json            ←  руками
```

Расширения (CryptoPro Cades / Контур.Плагин / стандартное Yandex) поставлены через UI.
Bridge-скрипты `~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge` — руками.

Verified против бинарника `26.3.1.1088`:

```
$ strings .../opt/yandex/browser/yandex_browser | grep -E "/etc/(opt|chromium)"
/etc/chromium/native-messaging-hosts
/etc/opt/yandex/browser/policies
```

Yandex также шипит свою экстеншн «Коллекции» через тот самый external-механизм:

```
$ cat .../opt/yandex/browser/Extensions/ghjgbemlcjioaaejhnnmgfpiplgalgcl.json
{
  "external_update_url": "https://yastatic.net/collections/_/assets/extensions/updates.xml",
  "experiment": "cdt2"
}
```

## Подходы

### 1. Установка пакета

| Вариант | Состояние | Поддержка extensions | Комментарий |
|---|---|---|---|
| `miuirussia/yandex-browser.nix` (используется сейчас) | живой, last commit **2026-04-09**, авто-обновление JSON | **есть `extensions`-параметр, но он dead-stub** — не используется внутри `browser/default.nix` | актуальная версия, x86_64-linux, поверх собственного nixpkgs-fork; `permittedInsecurePackages` уже выставлен внутри его flake |
| `teu5us/nix-yandex-browser` | **archived 2026-03-29**, last commit Feb 2025 | работает: создаёт `Extensions/<id>.json` через override | устаревший пакет, не следует за обновлениями Yandex |
| nixpkgs | в основной репо `yandex-browser` нет (issue #128761 закрыт без merge'а) | — | официально не поддерживается Nixpkgs из-за legal-вопросов про Yandex Russian root CA |

**Рекомендация:** оставить `miuirussia` как пакет. Дописать
patch-overlay в репо (см. ниже «Рекомендуемая архитектура»), который добавляет
к `miuirussia.yandex-browser-stable` post-install шаг, кладущий
`Extensions/<id>.json` файлы по списку расширений — копия паттерна из
`teu5us/package/default.nix`, но как overlay поверх `miuirussia`-пакета,
чтобы не форкать его сборку.

Альтернатива — использовать `extraInstallCommands` в `symlinkJoin` поверх
`miuirussia`-пакета, чтобы не пересобирать его деривацию полностью.

### 2. Декларативная установка расширений

#### Способ A — `ExtensionInstallForcelist` через `policies/managed/*.json`

Не работает: Yandex явно ограничивает эту политику для безопасности
([yandex.ru/support/browser/security/check-extensions](https://yandex.ru/support/browser/en/security/check-extensions.html?lang=en) +
комментарий в `teu5us/modules/home-manager/default.nix`):

> «Unlike Chromium, Yandex Browser disallows the use of ExtensionInstallForcelist
>  or "force_install" in ExtensionSettings, so we override the browser package instead.»

Имя политики `ExtensionInstallForcelist` существует в бинарнике (видно по `strings`),
но on-disk применение приводит к тому, что browser отказывается ставить
из неё расширения, или ставит, но удаляет при первом же запуске
(модель угроз: malicious enterprise force-install).

#### Способ B — external-extensions через `Extensions/<id>.json` рядом с бинарём (РЕКОМЕНДУЕМЫЙ)

Это нативный Chromium-механизм external-extensions. Файл рядом с бинарём:

```
$out/opt/yandex/browser/Extensions/<extension-id>.json
```

Содержимое для онлайн-установки/обновления:

```json
{ "external_update_url": "https://clients2.google.com/service/update2/crx" }
```

или для локального CRX:

```json
{
  "external_crx": "/nix/store/.../my-ext.crx",
  "external_version": "1.2.3"
}
```

Источники update_url, проверенные Chromium-паттерном (Yandex наследует поведение):

| URL | Описание | Что обычно отдаёт |
|---|---|---|
| `https://clients2.google.com/service/update2/crx` | Chrome Web Store | manifest XML `<gupdate>` с CRX URL для Chrome-only расширений |
| `https://addons.opera.com/extensions/update/` | Opera Add-ons | работает для Opera-store расширений (CryptoPro Cades живёт там — MV2-only) |
| `https://edge.microsoft.com/extensionwebstorebase/v1/crx` | Edge Add-ons | для Edge-store расширений |
| `https://yastatic.net/.../updates.xml` | Yandex CDN | используется самим Yandex для встроенных расширений |
| локальный путь через `external_crx` | nix-store CRX | надёжнее всего: pin'ится через хеш |

**Важно для нашего use-case:**
- CryptoPro Cades (`epebfcehmdedogndhlcacafjaacknbcm`) — **в Opera Add-ons**, MV2.
  `external_update_url` = `https://addons.opera.com/extensions/update/` — гипотеза, не проверено.
  Альтернатива: скачать CRX и положить через `external_crx`.
- Контур.Плагин (`momffihklfhkoakghidmkdocdkbfmoac`) — стоит из Chrome Web Store,
  должен установиться через `https://clients2.google.com/service/update2/crx`.
- Стандартный Yandex (`nngceckbapebfimnlniiiahkandclblb`) — встроен Yandex, не нужно ставить.

**Ограничение:** даже через external-механизм пользователь может удалить расширение
вручную, и оно не переустановится автоматически, пока в
`~/.config/yandex-browser/Default/Preferences` не очистится поле
`external_uninstalls` (см. комментарий в `teu5us`-модуле).

#### Способ C — `programs.chromium.extensions` из nixpkgs

Не подойдёт: модуль `programs.chromium` в nixpkgs кладёт policies в
`/etc/chromium/policies/managed/`, `/etc/opt/chrome/policies/managed/` и
`/etc/brave/policies/managed/` — но **не** в `/etc/opt/yandex/browser/policies/managed/`.
Кроме того, он использует `ExtensionInstallForcelist` (Способ A), который
в Yandex заблокирован.

### 3. Настройки расширений

Политика `ExtensionSettings` существует в Yandex.Browser (имя есть в бинарнике),
формально может быть использована для:
- ограничения по версиям (`min_version`, `update_url`),
- блокировки прав (`blocked_permissions`),
- запрета MV3/MV2 уровня (`installation_mode: "blocked"|"allowed"`).

Но `installation_mode: "force_installed"` в Yandex проигнорируется по тем же
причинам, что и `ExtensionInstallForcelist`.

Передать API-ключ или toggle конкретному расширению через **managed storage** —
стандартный Chromium-механизм через JSON-policy, поле `3rdparty.extensions`:

```json
{
  "3rdparty": {
    "extensions": {
      "epebfcehmdedogndhlcacafjaacknbcm": {
        "ExampleSetting": "value"
      }
    }
  }
}
```

Расширение получает это через `chrome.storage.managed.get()`. Поддерживается ли
конкретно в Yandex — **гипотеза, требует проверки** на `chrome://policy/` (надо
открыть browser после рестарта и посмотреть, увидит ли он `3rdparty`-секцию).

Для нашего стека (CryptoPro Cades / Контур.Плагин) мне источников про managed
storage не попалось — расширения управляются через установленный native host
(КриптоПро CSP / kontur.plugin внутри distrobox). Никаких user-tunable настроек
у них нет, decoupled через native messaging.

### 4. Browser-policies

#### Где Yandex.Browser ищет policies

Подтверждено `strings .../yandex_browser` и
[документацией alt-домена](https://docs.altlinux.org/ru-RU/alt-domain/11.1/html/alt-domain/yandex.html):

```
/etc/opt/yandex/browser/policies/managed/*.json     ← machine-level managed
/etc/opt/yandex/browser/policies/recommended/*.json ← machine-level recommended
```

User-level policies (`~/.config/yandex-browser/policies/`) Chromium-форки обычно
не читают на Linux — это Windows-only. Не проверено для Yandex.

Несколько JSON-файлов в одном каталоге **сливаются**, последний прочитанный
переопределяет конфликты (поведение Chromium). Имя файла не важно.

#### Какие политики поддерживаются

1. Весь `Chromium`-набор: `ExtensionInstall*`, `URLBlocklist`, `URLAllowlist`,
   `HomepageLocation`, `DefaultSearchProviderEnabled`, `PasswordManagerEnabled`,
   `SyncDisabled`, `DeveloperToolsAvailability`, `BrowserSignin`, …
   (см. [chromeenterprise.google/policies](https://chromeenterprise.google/policies/)).
2. **Yandex-специфичные** (458 строк `Yandex…` в бинарнике, ~100 из них —
   политики). Полезные:
   - `YandexAdblock` — отключить встроенный adblock.
   - `YandexEcomEnabled` / `YandexNtpClockEnabled` / `YandexNtpSmartboxEnabled` /
     `YandexNtpWidgets` — управление New Tab Page.
   - `YandexLoginAllowedDomains` / `YandexLoginAllowedDomainsForceLogout` —
     ограничение доменов залогинивания.
   - `YandexDisableID`, `YandexDisableSafeBrowsingLookup` —
     отключение телеметрии/safebrowsing.
   - `YandexEnableNeuroSearch`, `YandexAliceMsgDisable` — ML/AI features.
   - `YandexCopyAllowlist` / `YandexCopyBlocklist` /
     `YandexPasteAllowlist` / `YandexPasteBlocklist` — копирование/вставка.
   - `YandexDownloadRestrictionsEnabled` + `…AllowedTypes` / `…BlockedTypes`.
   - `YandexProtectedModeAllowList`.

   Полный список: см. [browser.yandex.ru/support/browser-corporate/policy/](https://browser.yandex.ru/support/browser-corporate/policy/) (страница может быть закрыта 403 от не-РФ IP — открывается через VPN/Firefox).

#### Управление из NixOS

Образец паттерна — `nixos/modules/programs/chromium.nix` upstream, секция config:

```nix
environment.etc = lib.mkIf cfg.enable {
  "opt/yandex/browser/policies/managed/default.json".text = builtins.toJSON {
    HomepageLocation = "https://nixos.org";
    PasswordManagerEnabled = false;
    SyncDisabled = true;
    YandexAdblock = false;
    YandexNtpClockEnabled = false;
    # …
  };
};
```

Через home-manager **не получится** — `~/.config/yandex-browser/policies/`
Yandex.Browser не читает (Linux Chromium-policies всегда system-wide).
Альтернатива на user-level — `initial_preferences`-файл (см. раздел 6).

### 5. NativeMessagingHosts декларативно

#### Где Yandex.Browser ищет NM-манифесты

Подтверждено `strings`:

```
system-wide: /etc/chromium/native-messaging-hosts/<name>.json
user:        ~/.config/yandex-browser/NativeMessagingHosts/<name>.json
             ~/.config/yandex-browser-beta/NativeMessagingHosts/<name>.json
```

То есть Yandex переиспользует chromium-системный путь (одна точка для всех
chromium-форков на одной машине), а user-level — свой собственный per-browser.

#### Готовых модулей нет

- `programs.chromium.enablePlasmaBrowserIntegration` (nixpkgs) — кладёт ровно
  один манифест KDE Plasma и не годится как общий API.
- `programs.chromium.nativeMessagingHosts` (home-manager) — **есть**, но только
  для `chromium`/`google-chrome`/`brave`/`vivaldi`. Yandex не в списке.
  Делает `symlinkJoin paths` → `${configDir}/NativeMessagingHosts`,
  где `paths` — список пакетов, экспортирующих
  `etc/chromium/native-messaging-hosts/<name>.json`. Тот же подход годится для
  Yandex с подменой `configDir = ".config/yandex-browser"`.

#### Системно vs user

| | `/etc/chromium/native-messaging-hosts/` | `~/.config/yandex-browser/NativeMessagingHosts/` |
|---|---|---|
| Где описывается | `environment.etc."chromium/native-messaging-hosts/<n>.json"` | `home.file.".config/yandex-browser/NativeMessagingHosts/<n>.json"` |
| Кто видит | все chromium-based браузеры на машине | только Yandex.Browser (stable) |
| Multi-user | один манифест всем | нужен home-manager на каждого |
| `path` в манифесте | абсолютный, доступный root и user | абсолютный, может быть в `~` |

**Рекомендация для нашего случая:** оба варианта работают. Системный (`/etc/chromium/...`)
чище — bridge-скрипты в `~/.local/bin/` уже user-specific (через path), системный
JSON просто говорит «вот NM-host с таким именем и origins». Минус: остальные
chromium-браузеры (если появятся) тоже его увидят — у нас сейчас Chrome стоит,
но он не имеет нужных расширений в `allowed_origins`, так что безопасно.

#### Пример декларативного манифеста

В системном модуле NixOS:

```nix
{ config, lib, ... }:
{
  environment.etc = {
    "chromium/native-messaging-hosts/ru.cryptopro.nmcades.json".text = builtins.toJSON {
      name = "ru.cryptopro.nmcades";
      description = "CryptoPro CAdES NMHost (bridged to distrobox 'tochka')";
      path = "/home/decard/.local/bin/nmcades-bridge";
      type = "stdio";
      allowed_origins = [
        "chrome-extension://iifchhfnnmpdbibifmljnfjhpififfog/"
        "chrome-extension://epebfcehmdedogndhlcacafjaacknbcm/"
      ];
    };
    # …аналогично для kd.nc и kontur.plugin
  };
}
```

Минус системного варианта: `path` в манифесте указывает на `/home/decard/.local/bin/`,
что нечисто (system-config зависит от user-state). Чистый вариант — положить
bridge-скрипты декларативно тоже (через `home.file` или `environment.etc`),
тогда NM-манифест будет ссылаться на nix-store-путь. Сейчас bridge-скрипты руками
в `~/.local/bin/` — переезд в home-manager описан в `docs/document-signing.md`
как «можно сделать позже».

### 6. Профиль и default-настройки

#### `initial_preferences` (хорошо для дефолтов первого запуска)

Yandex поддерживает chrome-style `initial_preferences` (он же `master_preferences`):
файл `master_preferences` рядом с бинарём (есть в нашей сборке —
`/nix/store/…/opt/yandex/browser/master_preferences`). Содержит JSON с
preferences-деревом, применяется только при первом запуске нового профиля.
Не подходит для "перезаписать поведение каждый раз" — для этого политики.

#### `home.file` для bookmarks/themes

Можно класть `~/.config/yandex-browser/Default/Bookmarks` через `home.file`,
но:
- браузер при запуске пересчитает контрольную сумму и **молча перезапишет**,
  если он уже стартовал и поднял профиль;
- любое изменение через UI потеряется при rebuild (или потеряется home-manager
  файл — в зависимости от `mkOutOfStoreSymlink`/`copy`).

**Рекомендация:** не класть Bookmarks/Themes/History/Cookies через nix.
Подходит для декларативного управления:
- `policies/managed/default.json` — поисковики (`DefaultSearchProvider*`),
  стартовая страница (`HomepageLocation`), отключение syncing/PasswordManager.
- `master_preferences` — тулбар, NTP-предложения первого раза.
- `External Extensions/<id>.json` (см. раздел 2-B) — расширения.
- `NativeMessagingHosts/` — манифесты (см. раздел 5).

Не подходит для декларатива:
- Bookmarks (используется в UI и записывается рантайм).
- Открытые вкладки / сессия.
- Установленные темы (через UI, состояние).
- Авторизации, синхронизация, куки.

## Рекомендуемая архитектура для этого репо

Один **системный модуль** + один **home-manager модуль**:

```
system/programs/yandex-browser.nix      # NEW: policies + system NM-hosts
home/programs/yandex-browser.nix        # EXISTING: пакет; ДОБАВИТЬ extensions overlay + home NM-hosts
```

### `system/programs/yandex-browser.nix` — содержит:

1. `environment.etc."opt/yandex/browser/policies/managed/00-base.json"` —
   общий набор политик (отключаем syncing, password-manager, telemetry,
   adblock, NTP-виджеты по вкусу). JSON генерируется из nix-attrset.
2. `environment.etc."chromium/native-messaging-hosts/ru.cryptopro.nmcades.json"` и
   аналоги для `kd.nc` и `kontur.plugin` — НО path в них указывает на
   nix-store-derivation bridge-скриптов, не на `~/.local/bin/`.

### `home/programs/yandex-browser.nix` — содержит:

1. `home.packages = [ (yandex-browser-with-extensions) ]`, где
   `yandex-browser-with-extensions` = `pkgs.symlinkJoin` поверх
   `inputs.yandex-browser.packages.${system}.yandex-browser-stable` с
   дополнительной фазой, которая создаёт `Extensions/<id>.json` файлы.
2. `home.file."Default/External Extensions/<id>.json"` или симметричный путь
   для каждого расширения — резервный путь (Chromium читает оба).
3. (Опционально) `home.file.".config/yandex-browser/NativeMessagingHosts/*.json"` —
   если решим оставить NM-host'ы user-level вместо системного `/etc/chromium/`.

### Bridge-скрипты декларативно

Сейчас они руками в `~/.local/bin/`. Декларатив:
```nix
home.file.".local/bin/nmcades-bridge" = {
  source = pkgs.writeShellScript "nmcades-bridge" ''
    #!/bin/sh
    unset LD_PRELOAD LD_LIBRARY_PATH
    export PATH=/etc/profiles/per-user/decard/bin:/run/current-system/sw/bin:/run/wrappers/bin:$PATH
    exec distrobox enter --no-tty tochka -- bash -c '
      pgrep -x pcscd || sudo -n /usr/sbin/pcscd
      exec /opt/cprocsp/bin/amd64/nmcades "$@"
    ' -- "$@"
  '';
  executable = true;
};
```

И всё, что нужно держать в bridge — там. Перенос с `~/.local/bin/`
описан в `docs/document-signing.md` как «можно потом» — это «потом» наступило.

### Итого структура файлов после рефакторинга

```
flake.nix                                                # без изменений
home/programs/yandex-browser.nix                         # пакет с extensions overlay + bridges + NM-host'ы
system/programs/yandex-browser.nix                       # NEW: policies/managed/*.json (опционально)
docs/document-signing.md                                 # обновить раздел «Bridges» — теперь декларативны
```

## Открытые вопросы и риски

1. **`addons.opera.com` как `external_update_url` — гипотеза.** В Chromium-форках
   это работает, но я не нашёл явного подтверждения от Yandex/третьих. Проверить
   эмпирически: положить json и посмотреть, ставится ли расширение CryptoPro
   при первом запуске.
   - Альтернатива (надёжная): скачивать CRX от miuirussia вручную или скриптом,
     класть в nix-store, использовать `external_crx`+`external_version`. Но это
     ломает автообновление — версия pin'ится в коде.

2. **Yandex может тихо удалять force-installed extensions через
   ML-сканер.** В офдоках упоминается ML, который удаляет «malicious»
   расширения 1-3 дня после публикации. CryptoPro Cades может туда попасть —
   на текущий момент не попадает, но риск есть. Бороться можно
   `ExtensionInstallAllowlist`-политикой — гипотеза, что она работает поверх
   ML-блокировки.

3. **`external_uninstalls` в Preferences.** Если пользователь удаляет
   расширение через UI, оно записывается в этот список и больше автоматически
   не ставится. Декларативного способа очистить этот список нет — придётся
   либо терпеть, либо вытирать `Preferences` (потеряет все настройки).
   Не блокирующая проблема, но известная грабля.

4. **`miuirussia` и `extensions` параметр.** Параметр объявлен, но `browser/default.nix`
   его не использует. Override `.override { extensions = […]; }` ничего не сделает.
   Нужно либо контрибьютить fix вверх, либо обходить через `symlinkJoin`/post-fixup
   overlay у нас в репо.

5. **Yandex Browser → `master_preferences` не пересоздаётся.** Файл лежит в
   nix-store-сборке в read-only состоянии. Перезаписать его per-user через
   home-manager — допустимо (надо передать абсолютный путь через
   `--user-data-dir` или подсунуть копию профиля). На текущий момент мы это
   не используем.

6. **Дополнительный chromium-форк** (Chrome) уже стоит. Если `environment.etc.
   "chromium/native-messaging-hosts/"` положит наши NM-host'ы туда —
   Chrome тоже их увидит, но `allowed_origins`-список не разрешает Chrome-extension
   `nngceckbapebfimnlniiiahkandclblb` (Yandex own ext). Безопасно, но имеет смысл
   класть только в Yandex-каталог, если боимся пересечения. Yandex же
   в `strings` явно ссылается на `/etc/chromium/native-messaging-hosts` — другого
   системного пути у него нет.

## Источники

- Bинарник Yandex.Browser 26.3.1.1088: пути политик и NM-host'ов выужены
  через `strings $out/opt/yandex/browser/yandex_browser`
  (verified в этом исследовании).
- [`miuirussia/yandex-browser.nix`](https://github.com/miuirussia/yandex-browser.nix) — flake-input в нашем репо, last commit 2026-04-09.
- [`teu5us/nix-yandex-browser`](https://github.com/teu5us/nix-yandex-browser) — archived 2026-03-29, паттерн `external_update_url` в `package/default.nix`.
- [`nixpkgs/nixos/modules/programs/chromium.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/chromium.nix) — образец policy-генератора `environment.etc."<browser>/policies/managed/*.json"`.
- [`home-manager/modules/programs/chromium.nix`](https://github.com/nix-community/home-manager/blob/master/modules/programs/chromium.nix) — образец extension-генератора `home.file."${configDir}/External Extensions/<id>.json"` и NM-hosts через `symlinkJoin`.
- [Chrome Native Messaging — Linux paths](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging) — системные пути для Chromium / Chrome.
- [Yandex Browser Corporate — Linux policy setup](https://browser.yandex.ru/support/browser-corporate/ru/deployment/linux/setting-policy) — официальный путь `/etc/opt/yandex/browser/policies/managed/`. Доступ может требовать РФ-IP/VPN.
- [`docs.altlinux.org` — управление политиками Yandex.Browser](https://docs.altlinux.org/ru-RU/alt-domain/11.1/html/alt-domain/yandex.html) — то же подтверждение пути.
- [Chrome Enterprise Policy List](https://chromeenterprise.google/policies/) — справочник Chromium-policies, большинство применимы к Yandex.
- [`yandex/browser-extensions` (GitHub)](https://github.com/yandex/browser-extensions) — официальный репо Yandex для своих браузерных расширений.
- [NixOS issue #128761](https://github.com/NixOS/nixpkgs/issues/128761) — почему yandex-browser не в nixpkgs.
- [Discourse: Yandex-browser link changed](https://discourse.nixos.org/t/yandex-browser-the-link-has-changed/38929) — community обсуждение пакета.
