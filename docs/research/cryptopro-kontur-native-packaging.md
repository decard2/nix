# Нативная упаковка КриптоПро / Контура для NixOS

> Research-документ. Не имплементация. Дата: 2026-04-29.

## TL;DR

**Реалистично, эту работу уже сделали**. Готовый и зрелый референс — `sakost/nixos`
(нативно собранный CryptoPro CSP + Cades + Rutoken + интеграция с Yandex.Browser
через `nmcades` proxy). Поверх него остаётся доупаковать Контур.Плагин (kontur.plugin.host),
Контур.Диагностика (Diag.Plugin.nc) и Контур.Updater (опционально) — все три
обычные ELF-бинари, которым нужны GTK3/cairo/libpcsclite, и они без проблем
правятся `autoPatchelfHook`-ом. Дополнительно есть `SomeoneSerge/pkgs`
(полная декомпозиция CSP по компонентам через generic.nix) и `danya02/cryptopro-nix`
(минимальный пример).

**Рекомендуемый подход:** `stdenv.mkDerivation` + `dpkg -x` (unpack-фаза)
+ `autoPatchelfHook` (build-фаза) + `cpconfig`-based set-up через
`system.activationScripts` и `systemd.tmpfiles.rules` (runtime). FHS не нужен,
nix-ld тоже. Для путей `/opt/cprocsp` и `/var/opt/cprocsp` — symlink-shim
через `tmpfiles` (NixOS позволяет создавать FHS-пути без рантайм-заворачивания).

**Объём работы:** ~4-6 человеко-часов чтобы переписать чужой пакет под наш
flake (бόльшую часть Nix-кода можно прямо скопировать с sakost/nixos), плюс
~1-2 часа на адаптацию для нашего набора (kontur.plugin не входит в sakost,
но это самые простые пакеты). Главный риск — лицензия КриптоПро (требует
ручного скачивания tarball'а через `requireFile`).

---

## Контекст и текущее состояние

Сейчас (см. `/home/decard/nix/docs/document-signing.md`) подписание завязано
на distrobox-контейнер `tochka` (Ubuntu 22.04). На хосте только
`yandex-browser` + udev-правило `MODE=0666` для `0a89:*` + bridge-скрипты
`~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge`, которые
`distrobox enter --no-tty tochka -- exec /opt/.../binary`.

Костыли в текущем решении:
- `unset LD_LIBRARY_PATH LD_PRELOAD` в bridge — Yandex навязывает свои nix-store пути
- `PATH=/etc/profiles/...:$PATH` (NM-child получает пустой PATH)
- `pgrep -x pcscd || sudo -n pcscd` внутри контейнера
- `MODE=0666` (не `0664+uaccess`) — потому что внутри distrobox sudo даёт mapped-root (subuid)
- systemctl-stub при инсталляции kontur-пакетов
- udevadm-stub для ifd-rutokens

Если переезжаем на нативку, все эти костыли исчезают.

---

## Подходы к упаковке проприетарных deb

### A. autoPatchelfHook — рекомендуемый

`pkgs.autoPatchelfHook` это `nativeBuildInputs`-хук, который после `installPhase`
проходит по всем ELF-файлам в `$out`, читает `DT_NEEDED`, ищет каждую `.so` в
`buildInputs` (а также `runtimeDependencies`) и переписывает:

- **interpreter** (`PT_INTERP`) — был `/lib64/ld-linux-x86-64.so.2`, станет
  `/nix/store/.../glibc/lib/ld-linux-x86-64.so.2`
- **DT_RPATH/DT_RUNPATH** — добавляет пути найденных libs

Когда работает:
- бинарь линкуется ДИНАМИЧЕСКИ (наш случай — все CSP/Cades/Kontur бинари именно такие)
- shared libs самого пакета лежат в одной папке → `addAutoPatchelfSearchPath`
- библиотеки, которые `dlopen()`-ятся в рантайме — указать в `runtimeDependencies`
  (autoPatchelf сам их добавит в RPATH)

Когда НЕ работает:
- бинарь читает `/etc/ld.so.cache` (нет на NixOS — но это рекдеп)
- бинарь делает `dlopen("libfoo.so")` без полного пути и без `LD_LIBRARY_PATH`
- бинарь сам читает `getauxval(AT_BASE)` или мрут на integrity check

Для нас: **работает для всех 8-10 пакетов**, что подтверждается тремя независимыми
nix-репо (sakost, SomeoneSerge, danya02 — для CSP + Cades) и shvedpkgs
(для librtpkcs11ecp).

Минимальный пример (наш случай — Cades plugin host nmcades):

```nix
{ stdenv, lib, dpkg, autoPatchelfHook, requireFile,
  pcsclite, gtk3, glib, pango, atk, gcc-unwrapped, libxcrypt-legacy
}:
stdenv.mkDerivation {
  pname = "cprocsp-pki-plugin-64";
  version = "2.0.15600-1";

  src = requireFile {
    name = "cprocsp-pki-plugin-64_2.0.15600-1_amd64.deb";
    url   = "https://cryptopro.ru/products/cades/downloads";
    hash  = "sha256-...";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  buildInputs = [
    pcsclite gtk3 glib pango atk
    gcc-unwrapped.lib  # libstdc++.so.6
    libxcrypt-legacy   # libcrypt.so.1
  ];

  # libcsp.so.4 / libcapi20.so.4 / librdrsup.so.4 ставятся отдельным пакетом
  # (cprocsp-csp / lsb-cprocsp-rdr) — они в RUNPATH /opt/cprocsp/lib/amd64.
  # Для autoPatchelf надо или включить эти пакеты в propagatedBuildInputs,
  # или передать через addAutoPatchelfSearchPath.
  autoPatchelfIgnoreMissingDeps = [
    "librdrsup.so.4"  # из lsb-cprocsp-base
  ];

  unpackPhase = "dpkg-deb -R $src .";

  installPhase = ''
    mkdir -p $out
    cp -r opt etc usr $out/
    mkdir -p $out/bin
    ln -s $out/opt/cprocsp/bin/amd64/nmcades $out/bin/nmcades
  '';

  preFixup = ''
    addAutoPatchelfSearchPath $out/opt/cprocsp/lib/amd64
  '';

  meta = with lib; {
    description = "CryptoPro Cades Browser Plug-in (NM host nmcades)";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
```

### B. buildFHSEnv — fallback

`pkgs.buildFHSEnv` создаёт chroot/bwrap-окружение с традиционным FHS-layout
(`/usr/bin`, `/lib`, `/etc`), куда биндятся nix-store-пути под видом FHS.
Внутри запускается команда — она «думает» что попала в Ubuntu.

Когда тащить:
- бинарь жёстко зашит на пути типа `/usr/bin/X` или `/etc/...`
  и эти пути **не патчатся** (например, обфусцированы)
- бинарь делает integrity-check на свой `dpkg --status`
- невозможно найти все `dlopen()`-зависимости (тогда внутри FHS можно бросить
  весь Ubuntu rootfs)

Минусы:
- Тяжёлая обёртка (~500MB FHS rootfs если тащить полную userland) — у нас уже
  есть distrobox, по сути это будет он же
- Native Messaging хост, запущенный в bwrap, будет жить в своей PID-namespace
  и ему понадобится bind-mount stdin/stdout от хоста
- pcscd через FHS работать **не будет** без bind-mount `/run/pcscd/pcscd.comm`

Для нас: **не нужно**. Все ключевые бинари (nmcades, csptest, certmgr,
kontur.plugin.host, Diag.Plugin.nc, kontur.updater) — обычный ELF без
integrity-check и с предсказуемыми путями.

### C. nix-ld — не подходит

`programs.nix-ld.enable = true` ставит на хост `/lib64/ld-linux-x86-64.so.2`
(глобально), который при запуске любого «Ubuntu-стиля» бинаря добавляет
в LD_LIBRARY_PATH стандартный набор glibc/libstdc++/...

Когда полезен: разовые бинари (драйверы, AppImage, pre-built python wheel).
Не подходит когда нужен **детерминированный rebuild** и стабильная PATH-цепочка.
Для системного сервиса (а у нас именно такой) nix-ld — не deterministic enough,
плюс закон Деметры (его LD_LIBRARY_PATH протекает в дочерние процессы).

### D. Гибрид: autoPatchelf + tmpfiles `/opt/cprocsp` symlink

В sakost/nixos применён красивый трюк, который мы будем использовать:

```nix
systemd.tmpfiles.rules = [
  "L+ /opt/cprocsp - - - - ${cryptopro}/opt/cprocsp"
  "d /var/opt/cprocsp 0755 root root - -"
  "d /etc/opt/cprocsp 0755 root root - -"
  "C /etc/opt/cprocsp/config64.ini 0644 root root - ${cryptopro}/etc/opt/cprocsp/config64.ini"
];
```

`L+` создаёт симлинк `/opt/cprocsp -> /nix/store/...`. После этого:
- хардкод `/etc/opt/cprocsp/license.ini` (есть в libtsp/libocsp/libcppcades) — работает
- хардкод `/etc/opt/cprocsp/trusted_sites.html` (libnpcades) — работает
- `cpconfig`-генерируемые `/etc/opt/cprocsp/config64.ini` записи с путями
  `/opt/cprocsp/lib/amd64/libcsp.so` — работают, потому что есть симлинк
- `/var/opt/cprocsp/users/<user>/keys/` — реальная директория, чтобы CSP мог
  туда писать ключи (она и в контейнерной версии живёт там же)

Это **не** FHS-окружение и **не** chroot — это просто три FHS-symlink-а на хосте.
Безопасно, минимально, не ломает остальную систему.

### Рекомендация для нашего стека

**autoPatchelfHook + symlink-shim через tmpfiles** = вариант D.

---

## Конкретные пакеты

### КриптоПро CSP

#### Что внутри tarball'а

`linux-amd64_deb.tgz` (~38 МБ) содержит ~50 .deb-пакетов, поверх которых лежит
`install.sh` который выбирает один из готовых наборов: `kc1`, `kc2`, `kc1+gui`, etc.
Минимально для нашего use-case (подпись через токен из браузера) нужны:

| Пакет | Что внутри | Зачем |
|---|---|---|
| `lsb-cprocsp-base` | директории `/opt/cprocsp/{bin,lib,sbin,share}/`, `/etc/opt/cprocsp/`, `/var/opt/cprocsp/{users,tmp,keys,...}/` | Базовый layout |
| `lsb-cprocsp-rdr-64` | `libcapi10.so.4`, `libcapi20.so.4`, `librdrsup.so.4`, `libcpext.so.4` | Reader API |
| `lsb-cprocsp-kc1-64` | `libcsp.so.4`, `librdrrndmbio_tui.so.4` | KC1 — крипто-ядро |
| `lsb-cprocsp-capilite-64` | `libcsp.so` API + `csptest`, `certmgr`, `cryptcp`, `cpinstance`, `cpconfig` | CLI и API |
| `lsb-cprocsp-pkcs11-64` | `libcppkcs11.so` | PKCS11 |
| `cprocsp-rdr-pcsc-64` | `librdrpcsc.so` (мост к PCSC-Lite) | Чтение токенов через `pcscd` |
| `cprocsp-rdr-rutoken-64` | `librdrrutoken.so` | Поддержка Rutoken Lite/S/ECP/ECP2 (ATR-распознавание) |
| `cprocsp-rdr-gui-gtk-64` | `librdrrndmbio_gui_fgtk.so`, `libfgcpui.so`, `xcpui_app` | GTK PIN-диалог |
| `cprocsp-pki-cades-64` | `libcades.so`, `libcppcades.so`, `libxades.so`, `libtsp.so`, `libocsp.so`, `tsputil`, `ocsputil` | CAdES SDK |
| `cprocsp-pki-plugin-64` | `nmcades`, `libnpcades.so` + NM-манифест `ru.cryptopro.nmcades.json` | Браузерный плагин |

`ifd-rutokens` (от Aktiv) — **не нужен**, libccid 1.7.1 сам понимает Rutoken Lite.
Подтверждено в текущем deploy'е (см. document-signing.md): «Rutoken Lite ≠ HID,
класс CCID, libccid 1.7.1 уже знает VID 0x0A89». Гентушный ebuild kontur-plugin
для надёжности тоже не использует ifd-rutokens.

#### Зашитые пути (проверено через `strings + objdump`)

Пути жёстко зашитые в код **(других нет)**:
- `/opt/cprocsp/lib/amd64` — RPATH во всех `.so` (можно перебить `patchelf --set-rpath`,
  что и делает autoPatchelfHook)
- `/etc/opt/cprocsp/license.ini` — `libocsp/libtsp/libcppcades`
- `/etc/opt/cprocsp/trusted_sites.html` — `libnpcades`

Пути `/var/opt/cprocsp/users/<user>/...` идут **через cpconfig API** — то есть
библиотека читает `config64.ini` и дальше делает то, что там написано. Это
хорошо: нам не надо патчить бинарь, мы просто пишем правильный `config64.ini`
через `cpconfig` команды на этапе установки.

#### Особенности линковки

`nmcades` — типичный ELF, RPATH=`/opt/cprocsp/lib/amd64`, NEEDED:
`librdrsup.so.4`, `libstdc++.so.6`, `libm.so.6`, `libgcc_s.so.1`, `libc.so.6`,
`ld-linux-x86-64.so.2`. Всё штатное.

`libnpcades.so.2.0.0` (3.8 МБ) — линкуется на `libssp.so.4` (CryptoPro
GOST TLS), `libcapi20.so.4`, `libstdc++.so.6`, всё родное.

`libcsp.so.4.0.5` (2.9 МБ) — самое сердце. Линкуется на `libcapi10.so.4`,
`libcapi20.so.4`, `librdrsup.so.4`, `libstdc++`, `libm`, `libdl`. Только
свои libs + glibc.

#### Стратегия упаковки

См. шаблон в разделе A выше + sakost/nixos cryptopro-csp.nix как референс.

Ключевые тонкости из чужого опыта:

1. **`libssp.so` НЕ симлинковать в `$out/lib/`** — иначе конфликт с GCC-овским
   stack-protector. Он должен быть **только** в `/opt/cprocsp/lib/amd64/` и
   подгружаться через RPATH:

   ```bash
   for solib in $out/opt/cprocsp/lib/amd64/*; do
     case "$(basename "$solib")" in
       libssp.so*) continue ;;
     esac
     ln -sf "$solib" "$out/lib/$(basename "$solib")"
   done
   ```

2. **`libpcsclite.so` подгружается через apppath, а не через dlopen/RUNPATH**:

   ```bash
   ${cpconfig} -ini '\config\apppath' -add string libpcsclite.so \
     ${pkgs.pcsclite.lib}/lib/libpcsclite.so
   ```

   Это значит cpconfig нужно запустить ОДИН РАЗ при установке (через
   activationScript), и записать туда правильный nix-store путь.

3. **`autoPatchelfIgnoreMissingDeps`** для `libcapi10/20`, `librdrsup`,
   `libssp` — потому что они приходят из соседних пакетов, и autoPatchelf
   на стадии каждого отдельного `mkDerivation` их не видит. Если упаковываем
   всё одним пакетом (как sakost) — этих ignore'ов не нужно.

4. **DisableIntegrity** — обязательно после patchelf'а:

   ```bash
   ${cpconfig} -ini '\config\parameters' -add string DisableIntegrity true
   ```

   КриптоПро при первом запуске считает SHA1 от своих `.so`, сравнивает с
   `/opt/cprocsp/lib/hashes/*` — после patchelf'а хэши не совпадают и CSP
   мрёт с `0x800B010A` (cert chain) или похожим. Sakost явно отключает.

5. **Triallicense**:

   ```bash
   ${cpconfig} -license -set '5050N-40030-01BT7-2MA83-QF3T0' -use_expired
   ```

   Это публичный 90-дневный trial-key, который КриптоПро сами раздают.
   Покупная лицензия записывается в `/etc/opt/cprocsp/license.ini` и
   sakost'овский setup-script её не перетирает (проверка через sentinel-файл).

#### Известные подводные камни

- **`csptestf` vs `csptest`** — есть оба, чуть разные опции, но в принципе
  взаимозаменяемы.
- **`/var/opt/cprocsp/users/<user>/stores/my.sto`** — пустой файл, который
  postinst создаёт под каждого пользователя >=UID 1000. Без него
  `certmgr -inst -store uMy` падает. На NixOS создаём через tmpfiles.
- **Rutoken-ATR registration** — `cpconfig -hardware media -add Rutoken/RutokenLite/...`
  должно вызываться с *правильными* ATR-байтами. У sakost полный набор для
  всех известных моделей (см. setupScript в репо). Это критично:
  без этого ваш токен не распознаётся.

### Cades Browser Plug-in (cprocsp-pki-cades-64 + cprocsp-pki-plugin-64)

Два пакета. Первый (`cades`) — это SDK/libs (`libcades.so`, `libcppcades.so`,
`libxades.so`, `libtsp.so`, `libocsp.so`, утилиты `tsputil`/`ocsputil`).
Второй (`plugin`) — собственно `nmcades` бинарь, `libnpcades.so` (для NPAPI,
устарел), и **NM-манифесты**:

```
/opt/google/chrome/extensions/iifchhfnnmpdbibifmljnfjhpififfog.json
/etc/chromium/native-messaging-hosts/ru.cryptopro.nmcades.json
/etc/opt/chrome/native-messaging-hosts/ru.cryptopro.nmcades.json
/usr/lib/mozilla/native-messaging-hosts/ru.cryptopro.nmcades.json
/usr/lib64/mozilla/native-messaging-hosts/ru.cryptopro.nmcades.json
/usr/share/chromium-browser/extensions/iifchhfnnmpdbibifmljnfjhpififfog.json
/usr/share/chromium/extensions/iifchhfnnmpdbibifmljnfjhpififfog.json
```

Для нашего use-case достаточно поставить манифест в:
- `/etc/yandex/browser/native-messaging-hosts/ru.cryptopro.nmcades.json` (system-wide для Yandex)
- ИЛИ `~/.config/yandex-browser/NativeMessagingHosts/ru.cryptopro.nmcades.json` (per-user)

Через NixOS-модуль удобнее system-wide через `environment.etc`:

```nix
environment.etc."yandex/browser/native-messaging-hosts/ru.cryptopro.nmcades.json".text =
  builtins.toJSON {
    name = "ru.cryptopro.nmcades";
    description = "...";
    path = "${cryptopro-cades}/bin/nmcades";  # nix-store путь напрямую!
    type = "stdio";
    allowed_origins = [
      "chrome-extension://iifchhfnnmpdbibifmljnfjhpififfog/"
      "chrome-extension://epebfcehmdedogndhlcacafjaacknbcm/"
    ];
  };
```

**Гипотеза:** `path` должен быть АБСОЛЮТНЫЙ (Chrome NM не делает PATH-resolution).
Тестировано всеми проектами выше. Однако `nix-store` пути меняются от ребилда
к ребилду — браузер при следующем NM-вызове прочтёт новый манифест и подцепит
новый путь. Если у тебя одновременно открыта вкладка с NM-сессией, она
останется на старом пути — но новые сессии получат новый.

#### Yandex.Browser специфика

Yandex (на основе Chromium) ищет манифесты в:

| Путь | Сфера |
|---|---|
| `/etc/yandex/browser/native-messaging-hosts/` | system-wide |
| `~/.config/yandex-browser/NativeMessagingHosts/` | user |
| `~/.config/yandex-browser-beta/NativeMessagingHosts/` | beta |

(см. postinst у diag.plugin — там точно эти пути.)

#### nmcades-proxy от sakost

Это **самая интересная часть** в sakost'овском пакете. Проблема: nmcades
проверяет «является ли сайт доверенным», вызывая extension через NM
(`is_approved_site:URL`). Extension должен ответить true/false. Если он
неверно отвечает — nmcades висит вечно. Чтобы это победить, sakost вставил
**python-прокси** между Yandex и nmcades:

```
Yandex --(NM stdio)--> nmcades-proxy.py --(stdio)--> nmcades
```

Прокси перехватывает `approved_site`-вопросы и:
1. Читает локальный файл `~/.config/cryptopro-trusted-sites`
2. Если URL в файле — возвращает true
3. Если нет — показывает zenity-диалог «Доверять?» и сохраняет ответ

Это эвристика, но оно работает (см. полный код в sakost cryptopro.nix).

В нашем случае мы можем взять либо это решение, либо просто использовать
расширение CryptoPro Cades из Opera Add-ons (которое умеет правильно
отвечать на approved_site через свой UI). У нас уже работает второй вариант
через distrobox — будет работать и нативно.

### Контур.Плагин (kontur.plugin)

#### Структура deb

```
/opt/kontur.plugin/kontur.plugin.host       (12 МБ, ELF, GTK)
/opt/kontur.plugin/kontur.plugin.assistant  (6 МБ, ELF, GTK)
/opt/kontur.plugin/pkcs11/libjckt2.so       (JaCarta)
/opt/kontur.plugin/pkcs11/libjcPKCS11-2.so
/opt/kontur.plugin/pkcs11/librtpkcs11ecp.so (Rutoken — устаревшая копия)
/opt/kontur.plugin/pkcs11/jcverify
/lib/systemd/system/kontur.plugin.assistant.service  (oneshot)
/lib/systemd/system/kontur.plugin.assistant.timer    (раз в час, RandomizedDelaySec=1200)
/etc/{chromium,opt/chrome,opt/edge}/native-messaging-hosts/kontur.plugin.json
/usr/lib{,64}/mozilla/native-messaging-hosts/kontur.plugin.json
```

`kontur.plugin.host` — наш Native Messaging host (его прописываем в
allowed_origins для расширения с ID `momffihklfhkoakghidmkdocdkbfmoac`).

#### ELF-анализ kontur.plugin.host

```
RPATH                ${ORIGIN}/lib
Interpreter          /lib64/ld-linux-x86-64.so.2
NEEDED libgtk-3.so.0, libgdk-3.so.0, libatk-1.0.so.0, libgio-2.0.so.0,
       libpangocairo-1.0.so.0, libgdk_pixbuf-2.0.so.0, libcairo-gobject.so.2,
       libpango-1.0.so.0, libcairo.so.2, libgobject-2.0.so.0, libglib-2.0.so.0,
       libdl.so.2, libpthread.so.0, libX11.so.6, libXext.so.6, libXinerama.so.1,
       libXfixes.so.3, libXcursor.so.1, libXrender.so.1, libXft.so.2,
       libfontconfig.so.1, libstdc++.so.6, libm.so.6, libgcc_s.so.1, libc.so.6
```

Все NEEDED — стандартный nixpkgs набор: `gtk3`, `glib`, `cairo`, `pango`,
`atk`, `gdk-pixbuf`, `xorg.libX11`, `xorg.libXext`, `xorg.libXinerama`,
`xorg.libXfixes`, `xorg.libXcursor`, `xorg.libXrender`, `xorg.libXft`,
`fontconfig`, `gcc-unwrapped.lib` (для libstdc++).

**Замечание про `RPATH=$ORIGIN/lib`:** папки `lib/` рядом с бинарём НЕТ.
Это «забронированный» RPATH на будущее. autoPatchelf его перетрёт на
nixpkgs-пути — это нормально и ожидаемо.

#### Захардкоженные пути

```
/etc/opt/skbkontur                          # директория конфигов (создаётся в postinst)
/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
/etc/pki/tls/certs/ca-bundle.crt
/etc/ssl/certs/ca-certificates.crt          # (на NixOS есть из cacert)
/opt/cprocsp/lib/amd64/libcapi20.so         # ← КРИТИЧНО: hardcoded путь к КриптоПро
/opt/cprocsp/sbin/amd64/cpconfig            # ← КРИТИЧНО: тоже hardcoded
/usr/bin/ntlm_auth
/usr/bin/xdg-open
/usr/lib/librtpkcs11ecp.so                  # дефолтный путь к Rutoken libs
/var/log/kontur.assistant
/var/tmp
```

`kontur.plugin.host` ОЖИДАЕТ КриптоПро по фиксированным путям `/opt/cprocsp/...`
и `/opt/cprocsp/sbin/amd64/cpconfig`. Это означает что **обязательно нужен
наш `tmpfiles` symlink `/opt/cprocsp -> $cryptopro/opt/cprocsp`** (вариант D).

#### Стратегия

```nix
{ stdenv, lib, dpkg, autoPatchelfHook, requireFile, makeWrapper,
  gtk3, glib, cairo, pango, atk, gdk-pixbuf, fontconfig,
  xorg, gcc-unwrapped, pcsclite
}:
stdenv.mkDerivation {
  pname = "kontur-plugin";
  version = "002875";

  src = requireFile {
    name = "kontur.plugin.002875.deb";
    url = "https://help.kontur.ru/plugin/linux";
    hash = "sha256-...";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = with xorg; [
    gtk3 glib cairo pango atk gdk-pixbuf fontconfig
    libX11 libXext libXinerama libXfixes libXcursor libXrender libXft
    gcc-unwrapped.lib
    pcsclite
  ];

  unpackPhase = "dpkg-deb -R $src .";

  installPhase = ''
    mkdir -p $out/{bin,opt/kontur.plugin,lib/systemd/user}
    cp -r opt/kontur.plugin/{kontur.plugin.host,kontur.plugin.assistant} $out/opt/kontur.plugin/
    # Внимание: НЕ копируем opt/kontur.plugin/pkcs11/ — оно ломает
    # плагин segfault'ом (см. msva/mva-overlay ebuild). Если нужен
    # JaCarta — берём отдельный пакет.

    # systemd-юниты для assistant (раз в час)
    cp lib/systemd/system/kontur.plugin.assistant.{service,timer} \
       $out/lib/systemd/user/
    # NB: переписать ExecStart на $out/opt/kontur.plugin/kontur.plugin.assistant
    substituteInPlace $out/lib/systemd/user/kontur.plugin.assistant.service \
      --replace "/opt/kontur.plugin/kontur.plugin.assistant" \
                "$out/opt/kontur.plugin/kontur.plugin.assistant"

    # NM-манифест (исходный путь /opt/kontur.plugin/kontur.plugin.host)
    install -Dm644 etc/chromium/native-messaging-hosts/kontur.plugin.json \
                   $out/share/native-messaging-hosts/kontur.plugin.json
    substituteInPlace $out/share/native-messaging-hosts/kontur.plugin.json \
      --replace "/opt/kontur.plugin/kontur.plugin.host" \
                "$out/opt/kontur.plugin/kontur.plugin.host"

    ln -s $out/opt/kontur.plugin/kontur.plugin.host $out/bin/kontur.plugin.host
  '';

  preFixup = ''
    addAutoPatchelfSearchPath $out/opt/kontur.plugin
  '';

  meta = with lib; {
    description = "Kontur Plugin (browser plugin for Diadoc, Kontur services)";
    homepage = "https://help.kontur.ru/plugin/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
```

**Postinst-действия (через NixOS-модуль):**

```nix
# kontur.plugin.host обращается к /opt/cprocsp/sbin/amd64/cpconfig — symlink уже есть
# kontur.plugin.host пишет в /etc/opt/skbkontur и /var/tmp/skbkontur
systemd.tmpfiles.rules = [
  "d /etc/opt/skbkontur 0755 root root - -"
  "d /var/tmp/skbkontur 0755 root root - -"
  "d /var/tmp/skbkontur/plugin 0755 root root - -"
  "d /var/tmp/skbkontur/plugin/metrics 0777 root root - -"
];
# NM-манифест
environment.etc."yandex/browser/native-messaging-hosts/kontur.plugin.json".source =
  "${kontur-plugin}/share/native-messaging-hosts/kontur.plugin.json";
# Assistant timer (опционально, можно просто не активировать)
systemd.user.services."kontur.plugin.assistant".enable = true;
systemd.user.timers."kontur.plugin.assistant".enable = true;
```

### Контур.Диагностика (diag.plugin)

#### Структура deb

```
/opt/diag.plugin/Diag.Plugin.nc       (ELF, простой)
/opt/diag.plugin/nchost-askpass       (для PIN-ввода через polkit/sudo)
/opt/diag.plugin/diag.png
/opt/diag.plugin/skb_kontur_pub.key   (Astra Linux digsig key — нам не нужен)
/opt/diag.plugin/kd.nc.json           (NM манифест — копируется в ~/.config/...)
/etc/{chromium,opt/chrome,opt/edge}/native-messaging-hosts/kd.nc.json
/usr/lib{,64}/mozilla/native-messaging-hosts/kd.nc.json
```

#### ELF-анализ

`Diag.Plugin.nc`:
```
Interpreter /lib64/ld-linux-x86-64.so.2
NEEDED libpthread, libz, libc
RPATH /root/buildAgent/work/310002629d514b68/nchost/../bin   (мусор от CI)
```

Минимально зависимый — вообще не нужен GTK. Только pthread + zlib + libc.
Постпатчелф просто перепишет interpreter и RPATH на nix-store.

Хардкод: `/etc/pki/tls/certs/ca-bundle.crt`, `/usr/bin/ntlm_auth`,
`/usr/bin/pkexec`, `/usr/bin/sudo`, `/usr/bin/x-terminal-emulator`.

`pkexec` — нужен только если плагин просит установить root-сертификат
от ФНС/Минцифры (в нашем кейсе уже стоят). `x-terminal-emulator` — для
открытия терминала из диагностики (не критично).

#### Стратегия

Простейший пакет:

```nix
{ stdenv, lib, dpkg, autoPatchelfHook, requireFile, zlib }:
stdenv.mkDerivation {
  pname = "kontur-diag-plugin";
  version = "002623";
  src = requireFile {
    name = "diag.plugin_amd64_signed.002623.deb";
    url = "https://help.kontur.ru/plugin/";
    hash = "sha256-...";
  };
  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  buildInputs = [ zlib ];
  unpackPhase = "dpkg-deb -R $src .";
  installPhase = ''
    mkdir -p $out/{bin,opt/diag.plugin,share/native-messaging-hosts}
    cp -r opt/diag.plugin/* $out/opt/diag.plugin/
    cp etc/chromium/native-messaging-hosts/kd.nc.json \
       $out/share/native-messaging-hosts/
    substituteInPlace $out/share/native-messaging-hosts/kd.nc.json \
      --replace "/opt/diag.plugin/Diag.Plugin.nc" \
                "$out/opt/diag.plugin/Diag.Plugin.nc"
    ln -s $out/opt/diag.plugin/Diag.Plugin.nc $out/bin/Diag.Plugin.nc
  '';
}
```

### kontur.updater

Это auto-updater для kontur.plugin/kontur.diag/etc. Запускается раз в час
из `kontur.updater.timer`, скачивает свежие deb'ы с api.kontur.ru, ставит
через `dpkg`. **На NixOS он не будет работать** — потому что нет dpkg в
системе и нет write-access к `/usr/lib/systemd/system/`.

**Рекомендация: просто не упаковывать.** Обновление через `nix flake update`
+ обновление хэшей deb-файлов в нашем nix-выражении. Это естественнее
nixos-way, чем самообновляющийся демон.

Если очень хочется — можно создать systemd.user.timer, который запускает
скрипт «проверь свежую версию через https://help.kontur.ru/files/kontur.plugin_amd64.deb,
если хэш отличается — пиши предупреждение в журнал», но не пытаться ставить.

---

## PCSC и USB-токен

### Что включить на хосте

На NixOS у нас уже есть `system/services/smartcard.nix` с udev-правилом
`MODE=0666` для `0a89:*`. Это нужно убрать (`MODE=0666` — нужно только
для распробокса, см. пояснение в комментарии модуля). Заменить на
стандартное:

```nix
services.pcscd = {
  enable = true;
  plugins = [ pkgs.ccid ];  # libccid 1.7.x умеет Rutoken Lite
};

services.udev.packages = [ pkgs.libu2f-host ];
# (Rutoken не требует кастомного udev — libccid сам его claim'ит)
```

Не путать с текущим состоянием: сейчас `services.pcscd.enable` явно НЕ
указан, потому что когда был включён, он мешал контейнеру (хост-pcscd
claimed device, container-pcscd не мог его получить). После переезда
на нативку **наоборот: pcscd на хосте — единственный, и он будет работать**.

### libccid vs ifd-rutokens

В hardcoded debs от КриптоПро есть `ifd-rutokens` — это драйвер от Aktiv
для Rutoken S (старое поколение, USB-class HID). Установка `ifd-rutokens`
ставит `.bundle/Contents/Linux/libifdrutokens.so` в `/usr/lib/pcsc/drivers/`,
и pcscd при следующем сканировании его подхватывает.

**Для Rutoken Lite (USB-class CCID, наш случай) ifd-rutokens НЕ НУЖЕН.**
libccid 1.7.x содержит правила для всех современных Aktiv-VID (`0x0A89`)
и нормально работает.

Если поставить оба — конфликта нет, но они оба могут попытаться claim'нуть
устройство, и pcscd выберет первый сработавший. Эмпирически из document-signing.md:
оставить только libccid, ifd-rutokens не ставить.

### librtpkcs11ecp

Это **PKCS11**-библиотека от Aktiv (отдельный софт, не CCID-драйвер).
Используется когда приложению нужен PKCS11 API (а не PCSC). Не наш случай:
- КриптоПро с Rutoken Lite ходит через PCSC + librdrrutoken (свой, проприетарный)
- Контур.Плагин по умолчанию ходит через КриптоПро (см. hardcoded
  `/opt/cprocsp/lib/amd64/libcapi20.so`)

Однако в `/opt/kontur.plugin/pkcs11/librtpkcs11ecp.so` лежит ИХ копия (старая
версия). Она **ломает плагин segfault'ом**, начиная с 4.2 (см. mva-overlay ebuild).
**Удаляем эту папку при упаковке.**

Если в будущем нужно будет работать через PKCS11 (например, для openssh-auth
по токену) — есть готовый пакет `ein-shved/shvedpkgs` с rtpkcs11ecp:

```nix
# pkgs/by-name/rt/rtpkcs11ecp/package.nix
src = fetchurl {
  url = "https://download.rutoken.ru/Rutoken/PKCS11Lib/${version}/Linux/x64/lib${pname}-${version}-1.x86_64.rpm";
  sha256 = "...";
};
```

### udev rules

После переезда на нативку, `MODE=0666` не нужен (pcscd запускается рутом
системно). Достаточно дефолтного `uaccess`-tag (он уже в pcscd udev-rules
из nixpkgs). Если pcscd на хосте запущен от root, MODE достаточно `0660 root pcscd`.

Однако если есть мысль работать с токеном НЕ через pcscd (например, прямой
PKCS11), тогда нужно `MODE=0660 GROUP=plugdev` или `TAG+="uaccess"` —
последнее автоматически даёт ACL active-user'у.

---

## Native Messaging интеграция с Yandex.Browser

### Куда класть манифесты

| Browser | System-wide path | User path |
|---|---|---|
| Yandex (stable) | `/etc/yandex/browser/native-messaging-hosts/` | `~/.config/yandex-browser/NativeMessagingHosts/` |
| Yandex (beta) | `/etc/yandex/browser-beta/native-messaging-hosts/` | `~/.config/yandex-browser-beta/NativeMessagingHosts/` |
| Chrome | `/etc/opt/chrome/native-messaging-hosts/` | `~/.config/google-chrome/NativeMessagingHosts/` |
| Chromium | `/etc/chromium/native-messaging-hosts/` | `~/.config/chromium/NativeMessagingHosts/` |
| Edge | `/etc/opt/edge/native-messaging-hosts/` | `~/.config/microsoft-edge/NativeMessagingHosts/` |
| Firefox | `/usr/lib/mozilla/native-messaging-hosts/` | `~/.mozilla/native-messaging-hosts/` |

**Не проверено:** `/etc/yandex/browser/...` — этот путь логически правильный
(Yandex форкнул Chromium и сохранил соглашения), но мы не нашли в их doc'ах
явного подтверждения. Гипотеза: **должен** работать, потому что `kontur.plugin`
postinst пишет именно туда. Проверить можно через `strace -f yandex-browser 2>&1 | grep native-messaging` после
старта.

### Манифест path → nix-store binary

```nix
environment.etc."yandex/browser/native-messaging-hosts/ru.cryptopro.nmcades.json".text =
  builtins.toJSON {
    name = "ru.cryptopro.nmcades";
    description = "CryptoPro Cades NM host";
    path = "${cryptopro-cades}/bin/nmcades";  # прямо к nix-store бинарю
    type = "stdio";
    allowed_origins = [
      "chrome-extension://iifchhfnnmpdbibifmljnfjhpififfog/"
      "chrome-extension://epebfcehmdedogndhlcacafjaacknbcm/"
    ];
  };
```

Yandex прочитает манифест, exec'нет `${cryptopro-cades}/bin/nmcades`, передаст
ему stdin/stdout. Без bridge-обёрток. **Ключевая разница с distrobox-сетапом**:
там нужен был bridge чтобы `unset LD_LIBRARY_PATH; distrobox enter ...`. Здесь
бинарь живёт в nix-store с правильным RPATH — никаких обёрток.

### home-manager или NixOS

Для системного решения (всех пользователей машины) — `environment.etc.*` в
NixOS-модуле. Для персонального (только под текущего пользователя) —
`xdg.configFile.* = "~/..."` в home-manager:

```nix
xdg.configFile."yandex-browser/NativeMessagingHosts/ru.cryptopro.nmcades.json".text =
  builtins.toJSON { ... };
```

Рекомендация: **NixOS-модуль**, чтобы манифесты переживали `home-manager backup`-ы
и были связаны с пакетом CSP по дереву зависимостей.

---

## Лицензия

КриптоПро CSP (`linux-amd64_deb.tgz`) распространяется под EULA-style
unfree-лицензией:
- Можно скачать после регистрации на cryptopro.ru
- Trial 90 дней (есть публичный 90-day-trial-key)
- Полная коммерческая лицензия — покупная (~1200 руб/раб.место)
- **Не редистрибутируемая.** Нельзя положить tarball в публичный nix cache.

Аналогично: kontur.plugin / diag.plugin — EULA, нельзя редистрибуть.

### requireFile pattern

```nix
src = pkgs.requireFile {
  name = "linux-amd64_deb.tgz";
  url = "https://cryptopro.ru/products/csp/downloads";
  hash = "sha256-e2rTgoKTHK1XviT2z5Zh2W9l7S44V/l2NG1BF7Lw1tg=";
  message = ''
    Download linux-amd64_deb.tgz from https://cryptopro.ru/products/csp/downloads
    (registration required), then add to local nix-store:

      nix-store --add-fixed sha256 ~/Downloads/linux-amd64_deb.tgz

    Then re-run: sudo nixos-rebuild switch --flake .#emerald
  '';
};
```

`requireFile` смотрит в `/nix/store/<hash>-<name>` и если файла нет —
печатает `message`. После того как пользователь сделает `nix-store --add-fixed`
(или эквивалент через `nix store add-file --hash-algo sha256 file`) — derivation
строится дальше.

### Где хранить tarball'ы локально

В нашем флейк-репо (`/home/decard/nix`) — **НЕ стоит** (git история, размеры).

Варианты:
1. **`~/Downloads/cryptopro/`** (текущее) + `nix-store --add-fixed` при первой сборке. Простой.
2. **Локальный binary cache** через `nix-serve` или `attic` — для второй машины.
3. **Локальный flake input типа `flake:cryptopro-source`** который указывает на
   локальный путь и не помещается в публичный кэш. Чуть сложнее, но
   удобнее для нескольких машин.

Для одной машины достаточно (1).

### Опыт упаковки проприетарных вещей в nixpkgs

| Софт | Пакет | Как сделано | Замечания |
|---|---|---|---|
| Skype | `pkgs.skypeforlinux` | autoPatchelfHook + dpkg + buildFHSEnv для GUI | Сейчас deprecated (Microsoft убрал Skype) |
| Teams (старый) | `pkgs.teams` | autoPatchelfHook + dpkg + electron wrapper | Тоже deprecated |
| AnyDesk | `pkgs.anydesk` | autoPatchelfHook + dpkg + tar.gz | Активно maintained |
| Viber | `pkgs.viber` | autoPatchelfHook + qt5 wrapping | Maintained |
| Vivaldi | `pkgs.vivaldi` | autoPatchelfHook + dpkg + wrapping для extensions | Один из канонических примеров |
| Slack | `pkgs.slack` | electron + autoPatchelfHook | |
| Dropbox | `pkgs.dropbox` | python wrapper + native blob через autoPatchelfHook | |

Все используют **тот же паттерн**: `dpkg-deb -x` или `tar -xJf` в `unpackPhase`,
затем `autoPatchelfHook` — это и есть «канон». КриптоПро ничем особенным не
отличается, кроме DisableIntegrity-trick (что есть и у других — у DiscoTweaks
и Steam-runtime тот же приём).

---

## Существующие решения community

| Репо | Что делает | Полезность для нас |
|---|---|---|
| [SomeoneSerge/pkgs](https://github.com/SomeoneSerge/pkgs/tree/master/pkgs/by-name/cp/cprocsp) | Декомпозиция CSP по 30+ компонентам через generic.nix; `requireFile`; `substituteInPlace` для путей `/etc/opt/cprocsp` → `$out/etc`; готов к подмене (не надо писать tmpfiles symlinks) | **Очень полезно как канонический референс**. Покрывает все компоненты CSP. Подход «всё в `$out`, никаких FHS» — но это требует переписать ВСЕ зашитые пути, что у нас бы значило патчить тоже `kontur.plugin.host`. Не делаем — лучше sakost-стиль с symlinks. |
| [sakost/nixos](https://github.com/sakost/nixos/blob/master/modules/programs/cryptopro.nix) | Полностью рабочее решение: cryptopro-csp.nix + module + nmcades-proxy.py + Yandex Browser wrapper + cpconfig setup + CA-сертификаты ФНС/Минцифры | **Главный референс, копировать почти as-is**. Не покрывает только Контур.Плагин (его там нет). |
| [danya02/cryptopro-nix](https://github.com/danya02/cryptopro-nix/blob/main/csp/flake.nix) | Минимальный пример (только GUI пакет cprocsp-rdr-gui-gtk-64) | Для обзора паттерна requireFile + autoPatchelfHook |
| [TheMaxMur/NixOS-Configuration](https://github.com/TheMaxMur/NixOS-Configuration/blob/master/flake.nix) | Использует SomeoneSerge/pkgs как input | Пример integration |
| [Corgiek/nixos-configuration](https://github.com/Corgiek/nixos-configuration) | Тоже использует cryptopro flake | Пример integration |
| [ein-shved/shvedpkgs](https://github.com/ein-shved/shvedpkgs/blob/master/pkgs/by-name/rt/rtpkcs11ecp/package.nix) | librtpkcs11ecp.so из rpm от download.rutoken.ru через rpmextract | Если понадобится PKCS11-доступ к Rutoken — готовый пакет |
| [msva/mva-overlay (Gentoo)](https://github.com/msva/mva-overlay/blob/master/www-plugins/kontur-plugin) | Контур.Плагин для Gentoo | **Полезный реверс-инжиниринг**: показывает что pkcs11/-папку надо удалить (segfault!), и какие deps реально нужны |
| [TheMaxMur/openssl-gost-nix](https://github.com/TheMaxMur/openssl-gost-nix) | OpenSSL с GOST-engine | Если будет нужен openssl с ГОСТ для CLI-задач |
| [chek1337/nixos-config](https://github.com/chek1337/nixos-config/blob/master/modules/desktop-env/x11-compat.nix) | XWayland + cryptopro-distrobox (как у нас) | Аналог нашего текущего решения; не помогает в нативной упаковке |

**Активного nixpkgs PR нет.** SomeoneSerge не пушил cprocsp в upstream
(скорее всего из-за лицензии и российских санкций — мейнтейнеры nixpkgs
не очень охотно мержат страновую крипту).

---

## systemd-зависимости

### Контур.Плагин

`kontur.plugin.assistant.timer` (раз в час) запускает
`kontur.plugin.assistant`, который сверяет состояние плагина и при
необходимости что-то проверяет.

**Декларативный аналог в NixOS:**

```nix
systemd.user.timers."kontur.plugin.assistant" = {
  description = "Periodic Kontur.Plugin assistant check";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "*:0";
    RandomizedDelaySec = "1200s";
    Persistent = true;
  };
};

systemd.user.services."kontur.plugin.assistant" = {
  description = "Kontur.Plugin assistant";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${kontur-plugin}/opt/kontur.plugin/kontur.plugin.assistant";
  };
  unitConfig = {
    After = [ "network-online.target" ];
    Wants = [ "network-online.target" ];
  };
};
```

Это user-timer (не system) — плагин работает в контексте графического
сеанса пользователя.

### Контур.Updater

**Не упаковываем, не нужен.** См. выше.

### postinst-скрипты

В постинсталле deb-ов вызывается `systemctl daemon-reload`, что в Nix-derivation
не нужно (мы не управляем live-системой через postinst, а только формируем `$out`).
То есть в derivation мы **просто не запускаем** postinst — копируем нужные файлы
руками в installPhase, остальное делает NixOS-модуль через декларацию.

В текущем distrobox-сетапе пришлось класть `/usr/local/bin/systemctl` stub, чтобы
postinst не падал. В нативной упаковке postinst в принципе не выполняется.

---

## GUI-зависимости плагинов

| Бинарь | Нужен X/Wayland | Нужен GTK | Нужен audio |
|---|---|---|---|
| nmcades | да (для PIN-диалога через `cprocsp-rdr-gui-gtk-64`) | gtk3 (через xcpui_app) | нет |
| kontur.plugin.host | да | gtk3 + cairo + pango + atk | нет |
| kontur.plugin.assistant | возможно (notify) | gtk3 | нет |
| Diag.Plugin.nc | нет | нет | нет |
| kontur.updater | нет | нет | нет |
| csptest, certmgr (CLI) | нет (если без `-pin`-prompt) | нет | нет |
| xcpui_app (PIN UI) | да | gtk3 | нет |

`gtk3` в nixpkgs — `pkgs.gtk3` (GTK 3.24.x, последний минор). Также нужно
проверить что:
- `XDG_DATA_DIRS` содержит `${gtk3}/share/gsettings-schemas/${gtk3.name}` —
  иначе при PIN-вводе будут warnings про неаренные schema'ы
- `wrapGAppsHook` (из nixpkgs) автоматически разруливает это через wrapper

Wayland-специфика:
- nmcades использует X11 (через GTK), на Hyprland это XWayland — должно
  работать прозрачно (sakost так и делает)
- если есть проблемы с координатами PIN-диалога — экспортировать `GDK_BACKEND=x11`

---

## Чем закончилась попытка нативно

Не нашёл публичной русскоязычной статьи (Habr) ровно на тему «КриптоПро
нативно на NixOS». Самая близкая — [Habr 706474 «КриптоПро в Linux контейнере
для использования КЭП от ФНС»](https://habr.com/ru/articles/706474/) —
именно про подход, на котором мы сейчас (Docker/distrobox).

Однако **в коде всё уже сделано** — sakost/nixos это именно «нативная
интеграция КриптоПро на NixOS». Этот репо — единственный, где есть полностью
рабочий стек (CSP + Cades + Yandex.Browser). Просто sakost не написал статью.

Отдельные обсуждения на NixOS Discourse:
- [Attempting to get requireFIle working...](https://discourse.nixos.org/t/attempting-to-get-requirefile-working-to-package-proprietary-software/40863)
- [Thankful for autoPatchelfHook](https://discourse.nixos.org/t/thankful-for-autopatchelfhook-for-library-dependency-tweaks/36029)

Habr-юзеров кто бы делал на NixOS — не нашёл.

---

## Дорожная карта (если решим делать)

### Этап 1: cryptopro-csp.nix (½ дня)

- [ ] Скопировать `sakost/packages/cryptopro-csp.nix` в наш `home/dev/cryptopro/csp.nix` (или `system/services/cryptopro/`)
- [ ] Подменить hash на тот что у нас (`nix hash file ~/Downloads/cryptopro/linux-amd64_deb.tgz`)
- [ ] Проверить `nix build .#cryptopro` — derivation собирается
- [ ] Проверить `csptest -enum_cont -fqcn -verifycontext` (увидеть container на токене)

**Риски:** autoPatchelfIgnoreMissingDeps может потребовать твика (другая
версия CSP — у нас 5.0.13003, у sakost было 5.0.12922).

### Этап 2: cryptopro module (½ дня)

- [ ] Скопировать `sakost/modules/programs/cryptopro.nix` в наш `system/services/cryptopro.nix`
- [ ] Заменить `services.pcscd.enable = true` (вместо текущего "не включаем")
- [ ] tmpfiles + activation script (cpconfig setup)
- [ ] CA-сертификаты ФНС (через fetchurl) + `certmgr -inst -store uRoot`
- [ ] Удалить нашу `system/services/smartcard.nix` (MODE=0666 больше не нужен)

**Риски:** activation script для cpconfig идёт ДО systemd-tmpfiles —
sakost решает это через ручное создание директорий в начале `text =`.

### Этап 3: nmcades + Yandex.Browser (½ дня)

- [ ] Native Messaging манифест в `/etc/yandex/browser/native-messaging-hosts/`
- [ ] Yandex.Browser wrapper с `LD_LIBRARY_PATH=/opt/cprocsp/lib/amd64` (из sakost)
- [ ] Расширение CryptoPro Cades из Opera Add-ons (вручную, как сейчас)
- [ ] Проверка cades_bes_sample.html — должно подгрузить плагин

**Риски:** sakost'овский nmcades-proxy.py может оказаться лишним — наш
existing test page уже работает с нашим extension. Если работает без proxy
— просто кладём прямой path к `nmcades`.

### Этап 4: kontur.plugin (½ дня)

- [ ] Написать derivation для `kontur.plugin.002875.deb`
- [ ] tmpfiles для `/etc/opt/skbkontur` + `/var/tmp/skbkontur`
- [ ] NM-манифест `kontur.plugin.json` (с правильным path → `${kontur-plugin}/bin/...`)
- [ ] systemd.user.timers.kontur.plugin.assistant (по желанию)

**Риски:** `kontur.plugin.host` требует cpconfig по `/opt/cprocsp/sbin/amd64/cpconfig`.
Этот symlink уже создан tmpfiles от cryptopro-модуля — должно работать.

### Этап 5: diag.plugin (¼ дня)

- [ ] Написать derivation для `diag.plugin_amd64_signed.002623.deb`
- [ ] NM-манифест `kd.nc.json`

**Риски:** минимальные, очень простой пакет.

### Этап 6: cleanup (¼ дня)

- [ ] Удалить bridge-скрипты `~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge`
- [ ] Удалить distrobox-контейнер `tochka` (или оставить как backup)
- [ ] Обновить `docs/document-signing.md` под новую архитектуру
- [ ] Удалить distrobox+podman из `home.packages` если они больше нигде не нужны

### Тестирование

После каждого этапа:
- `pcsc_scan` видит токен с правильным ATR (`Rutoken lite`)
- `csptest -keyset -enum_cont -fqcn -verifycontext` показывает контейнер
- `certmgr -list -store uMy` — наш сертификат
- `cades_bes_sample.html` — плагин загружен, версия, список сертификатов
- Точка: вход + подпись документа
- Диадок: вход + подпись документа

**Время на всё:** ~3 дня в одиночку с тестированием на реальном кейсе.
Без unfortunate surprise'ов — 1.5-2 дня.

---

## Открытые вопросы

1. **Yandex.Browser native-messaging-hosts system-wide путь:** наша гипотеза
   `/etc/yandex/browser/native-messaging-hosts/` основана на postinst kontur.plugin.
   Но у sakost он использует `/etc/opt/yandex/browser/native-messaging-hosts/`
   (см. environment.etc). Какой реально работает в текущей версии Yandex —
   проверить через `strace` после реального теста.

2. **Расширение CryptoPro Cades в Yandex.Browser:** оно живёт только в
   Opera Add-ons и ставится через её Web Store. Декларативно через
   home-manager не ставится (нет программного API). Альтернатива:
   `chromium.extensions = [ {id = "..."; updateUrl = "..."; } ];` —
   но это для policy-managed extensions, требует включения policy
   `ExtensionInstallForcelist`. Не знаю, поддерживает ли Yandex.Browser
   эту policy так же как Chromium. Гипотеза: да (он Chromium-fork), но
   проверять руками.

3. **Срок CA-сертификатов в setupScript.** Sakost фетчит `guc2022.crt`
   (Минцифры root) и `ca_fns_russia_2023_01.crt` (ФНС intermediate).
   Эти сертификаты могут истечь / поменяться. Нужен mechanism для
   обновления — простейший вариант это fetchurl с фиксированным URL и
   `nix-prefetch-url <url>` при ребилде. Лучше — fetchurl с meta-данными
   срока действия и пометки в README о ручном обновлении.

4. **Сборка под ISO/installer:** наш flake собирает ISO. Если в ISO
   попадёт cryptopro-модуль (через `system/installer.nix`), потребует
   `requireFile` источника — что не сработает на чистом installer'е.
   Решение: вынести cryptopro в отдельный модуль и **не включать** в installer
   profile.

5. **Когда обновлять КриптоПро.** Каждый новый minor version (5.0.13003 →
   5.0.14000) — нужно скачать tarball, перепосчитать `nix hash file`,
   обновить в наших `*.nix`. Не автоматизируется (требует регистрации).
   Можно через `flox`/`devenv` шаблон-команду, но всё равно вручную.

6. **Тестирование integrity-check после patchelf.** Sakost явно делает
   `cpconfig -ini '\config\parameters' -add string DisableIntegrity true` —
   вопрос, не падает ли что-то на следующих major-versions КриптоПро (мб
   они сделают integrity обязательным). Гипотеза: пока не отключали.

7. **Yandex.Browser передаёт LD_LIBRARY_PATH в child-процессы.** В нашем
   текущем bridge мы делаем `unset LD_LIBRARY_PATH`. После переезда:
   sakost'овский yandex-browser-wrapper делает `--suffix LD_LIBRARY_PATH : "/opt/cprocsp/lib/amd64"`,
   то есть **добавляет** путь, а не сбрасывает. Это работает потому что
   все nmcades libs — на правильных nix-store путях через RPATH, и
   `/opt/cprocsp/lib/amd64` (FHS-симлинк) тоже валидный. Тонкий момент:
   если nmcades-child наследует LD_LIBRARY_PATH от Yandex.Browser, и там
   `/nix/store/.../yandex-libs/lib`, то `nmcades` может найти **не свой**
   `libpthread.so.0` (например, более новой версии glibc). Нужно проверить
   это в реальной интеграции. Если ломается — добавить wrapper над nmcades:
   `unset LD_LIBRARY_PATH; export LD_LIBRARY_PATH=/opt/cprocsp/lib/amd64; exec ${nmcades}`.

---

## Источники

### Nixpkgs / nix-flakes
- [SomeoneSerge/pkgs — cprocsp/package.nix](https://github.com/SomeoneSerge/pkgs/blob/master/pkgs/by-name/cp/cprocsp/package.nix)
- [SomeoneSerge/pkgs — cprocsp/generic.nix](https://github.com/SomeoneSerge/pkgs/blob/master/pkgs/by-name/cp/cprocsp/generic.nix)
- [SomeoneSerge/pkgs — cprocsp/components.nix](https://github.com/SomeoneSerge/pkgs/blob/master/pkgs/by-name/cp/cprocsp/components.nix)
- [sakost/nixos — packages/cryptopro-csp.nix](https://github.com/sakost/nixos/blob/master/packages/cryptopro-csp.nix)
- [sakost/nixos — modules/programs/cryptopro.nix](https://github.com/sakost/nixos/blob/master/modules/programs/cryptopro.nix)
- [sakost/nixos — home/programs/gui-apps.nix (yandex-browser-with-cryptopro)](https://github.com/sakost/nixos/blob/master/home/programs/gui-apps.nix)
- [danya02/cryptopro-nix](https://github.com/danya02/cryptopro-nix/blob/main/csp/flake.nix)
- [ein-shved/shvedpkgs — rtpkcs11ecp](https://github.com/ein-shved/shvedpkgs/blob/master/pkgs/by-name/rt/rtpkcs11ecp/package.nix)
- [msva/mva-overlay — Gentoo kontur-plugin ebuild](https://github.com/msva/mva-overlay/blob/master/www-plugins/kontur-plugin/kontur-plugin-4.10.0.2633.ebuild)
- [TheMaxMur/openssl-gost-nix](https://github.com/TheMaxMur/openssl-gost-nix)
- [TheMaxMur/NixOS-Configuration — uses cryptopro flake](https://github.com/TheMaxMur/NixOS-Configuration/blob/master/flake.nix)

### Документация nixpkgs / NixOS
- [autoPatchelfHook docs](https://ryantm.github.io/nixpkgs/hooks/autopatchelf/)
- [auto-patchelf.sh source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/auto-patchelf.sh)
- [buildFHSEnv docs](https://ryantm.github.io/nixpkgs/builders/special/fhs-environments/)
- [chrome-token-signing — example NM host package](https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/chrome-token-signing/default.nix)
- [chromium NM module (release-25.11)](https://github.com/NixOS/nixpkgs/blob/release-25.11/nixos/modules/programs/chromium.nix)
- [Nixpkgs/Building RPM DEB with nixpkgs (NixOS Wiki)](https://nixos.wiki/wiki/Nixpkgs/Building_RPM_DEB_with_nixpkgs)
- [Discourse: requireFile for proprietary software](https://discourse.nixos.org/t/attempting-to-get-requirefile-working-to-package-proprietary-software/40863)
- [Discourse: Thankful for autoPatchelfHook](https://discourse.nixos.org/t/thankful-for-autopatchelfhook-for-library-dependency-tweaks/36029)
- [Native Messaging API (Chrome dev)](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging)

### Производители
- [CryptoPro CSP Linux downloads](https://cryptopro.ru/products/csp/downloads)
- [CryptoPro CAdES Browser Plug-in](https://cryptopro.ru/products/cades/downloads)
- [Kontur.Plugin Linux page](https://help.kontur.ru/plugin/linux)
- [Kontur.Extern Linux requirements](https://www.kontur-extern.ru/info/trebovaniya-dlya-raboty-na-linux)
- [Rutoken Lite GNU/Linux docs](https://dev.rutoken.ru/pages/viewpage.action?pageId=72451917)
- [Rutoken PKCS11ECP library](https://www.rutoken.ru/support/download/pkcs/)

### Habr / community
- [«КриптоПро в Linux контейнере...» (Habr 706474)](https://habr.com/ru/articles/706474/) — текущий подход
- [«Работа с СКЗИ и аппаратными ключевыми носителями в Linux» (Habr 441212)](https://habr.com/ru/companies/alfa/articles/441212/) — общие сведения
- [Forum.rutoken.ru thread на Linux установку Контур.Плагин](https://forum.rutoken.ru/topic/3523/)
- [pushorigin: «Как получить рабочий сертификат КриптоПро и установить на Linux»](https://pushorigin.ru/cryptopro/real-cert-crypto-pro-linux)

### Текущая локальная информация
- `/home/decard/nix/docs/document-signing.md` — текущий distrobox-стек
- `/home/decard/nix/system/services/smartcard.nix` — udev MODE=0666 (выпиливается)
- `/home/decard/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge` — bridge-скрипты (выпиливаются)
- `/home/decard/Downloads/cryptopro/linux-amd64_deb.tgz` — tarball CSP 5.0.13003-7
- `/home/decard/Downloads/cades-linux-amd64.tar.gz` — Cades plug-in 2.0.15600-1
- `/home/decard/Downloads/{kontur.plugin.002875,kontur.updater.002723,diag.plugin_amd64_signed.002623}.deb`
