# Подписание документов аппаратным ключом

Стек для подписи документов в Точке, Диадоке и подобных сервисах токеном **Rutoken Lite** (Aktiv USB ID `0a89:0025`) на NixOS — без Windows-VM.

## Архитектура

КриптоПро CSP, Cades Browser Plug-in и Контур.Плагин не пакетируются в nixpkgs (проприетарные deb-ы). Чтобы не разрушать чистоту хоста, они живут в **distrobox-контейнере на Ubuntu 22.04**, а нативный Yandex.Browser на хосте общается с ними через **bridge-скрипты** (Chrome Native Messaging).

```
                          Хост (NixOS)
┌──────────────────────────────────────────────────────────┐
│  Yandex.Browser (nix-store, native)                      │
│      ↕ Native Messaging (stdio)                          │
│  ~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge       │
│      ↕ exec: distrobox enter --no-tty tochka -- ...      │
└────────────────────────┬─────────────────────────────────┘
                         │
              distrobox-контейнер `tochka` (Ubuntu 22.04)
┌────────────────────────▼─────────────────────────────────┐
│  /opt/cprocsp/bin/amd64/nmcades         ← КриптоПро Cades │
│  /opt/diag.plugin/Diag.Plugin.nc        ← Контур.Диаг.    │
│  /opt/kontur.plugin/kontur.plugin.host  ← Контур.Плагин   │
│      ↕                                                    │
│  pcscd (запускается лениво из bridge через sudo NOPASSWD) │
│      ↕                                                    │
│  libccid → /dev/bus/usb/001/N (Rutoken Lite, MODE=0666)  │
└──────────────────────────────────────────────────────────┘
```

Решение по «отдельный браузер vs основной Chrome»: Chrome 147 удалил поддержку Manifest V2 (расширение CryptoPro Cades только в MV2 и удалено из Web Store в феврале 2025). КриптоПро официально рекомендует **Yandex.Browser** или Chromium-Gost. Yandex.Browser держит рабочее расширение в Opera Add-ons и MV2 не отключал.

## Компоненты в репо

```
flake.nix                              # input yandex-browser
home/programs/yandex-browser.nix       # пакет из flake
system/services/smartcard.nix          # udev MODE=0666 для 0a89:*
```

`home-manager` НЕ управляет bridge-скриптами и NM-манифестами — они лежат в `~/.local/bin/` и `~/.config/yandex-browser/NativeMessagingHosts/` соответственно. Их можно перенести в home-manager позже, если захочется infra-as-code.

## Установка с нуля

### 1. Хост (NixOS)

```bash
# уже в репо: flake input + home/programs/yandex-browser.nix + udev rule + distrobox/podman в home.packages
sudo nixos-rebuild switch --flake .#emerald
# переткнуть токен — udev назначит MODE=0666
```

Проверить: `ls -la /dev/bus/usb/001/N` где N — devnum токена → `crw-rw-rw-`.

### 2. Контейнер

```bash
distrobox-create --name tochka --image docker.io/library/ubuntu:22.04 --yes
distrobox enter --no-tty tochka -- bash -c '
  sudo apt-get update
  sudo apt-get install -y libccid pcscd libpcsclite1 pcsc-tools opensc usbutils libusb-1.0-0 alien curl gnupg
'
```

### 3. КриптоПро CSP + Cades Browser Plug-in (внутри контейнера)

Скачать `linux-amd64_deb.tgz` (CSP 5.0 R3) с https://cryptopro.ru/products/csp/downloads (требует регистрации) и `cades-linux-amd64.tar.gz` (Cades 2.0.15600+) с https://cryptopro.ru/products/cades/plugin/get_2_0.

```bash
distrobox enter --no-tty tochka -- bash -c '
  cd /tmp && tar xzf ~/Downloads/linux-amd64_deb.tgz
  cd /tmp/linux-amd64_deb
  sudo ./install.sh kc1 cprocsp-rdr-rutoken cprocsp-rdr-pcsc cprocsp-rdr-gui-gtk lsb-cprocsp-pkcs11 cprocsp-pki-cades cprocsp-pki-plugin

  # Workaround: ifd-rutokens postinst падает на отсутствие udevadm
  sudo sh -c "echo \"#!/bin/sh\nexit 0\" > /usr/local/bin/udevadm && chmod +x /usr/local/bin/udevadm"
  sudo dpkg -i ifd-rutokens_1.0.4_amd64.deb

  # обновить cades-plugin до последней версии
  cd /tmp && tar xzf ~/Downloads/cades-linux-amd64.tar.gz
  cd /tmp/cades-linux-amd64
  sudo dpkg -i cprocsp-pki-cades-64_*.deb cprocsp-pki-plugin-64_*.deb
'
```

Установить сертификат с токена в личное хранилище CSP:

```bash
distrobox enter --no-tty tochka -- bash -c '
  CONT=$(/opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -fqcn -verifycontext 2>/dev/null \
    | grep "@" | tail -1 | tr -d " ")
  /opt/cprocsp/bin/amd64/certmgr -inst -store uMy -cont "$CONT"
'
```

### 4. NOPASSWD-sudo для pcscd внутри контейнера

```bash
distrobox enter --no-tty tochka -- bash -c '
  echo "decard ALL=(root) NOPASSWD: /usr/sbin/pcscd" \
    | sudo tee /etc/sudoers.d/pcscd >/dev/null
  sudo chmod 440 /etc/sudoers.d/pcscd
'
```

### 5. Контур: diag.plugin + kontur.plugin + kontur.updater

`kontur.plugin.host` — это плагин подписания для Контур.Диадок и других сервисов Контура. Скачать со https://help.kontur.ru/plugin/linux:
- `diag.plugin_amd64_signed.*.deb`
- `kontur.plugin.*.deb`
- `kontur.updater.*.deb`

Postinst-скрипты вызывают `systemctl daemon-reload`, который падает в контейнере без systemd-as-pid-1 — кладём stub перед установкой:

```bash
distrobox enter --no-tty tochka -- bash -c '
  echo "#!/bin/sh
exit 0" | sudo tee /usr/local/bin/systemctl >/dev/null
  sudo chmod +x /usr/local/bin/systemctl

  sudo dpkg -i ~/Downloads/diag.plugin_amd64_signed.*.deb \
                ~/Downloads/kontur.updater.*.deb \
                ~/Downloads/kontur.plugin.*.deb

  sudo rm /usr/local/bin/systemctl
'
```

После установки `kontur.plugin` создаст `/etc/chromium/native-messaging-hosts/kontur.plugin.json` — это ссылка на `/opt/kontur.plugin/kontur.plugin.host`, который и будет нашим бэкендом для bridge.

### 6. Bridge-скрипты на хосте

Три скрипта в `~/.local/bin/`. Все одинаковой формы — отличается только бинарь, который exec'ится в контейнере.

**Общая логика, которую важно сохранить:**
- shebang `#!/bin/sh` (НЕ `/usr/bin/env bash` — у NM-child'а PATH=`/usr/bin:/bin`, а на NixOS там нет bash)
- `unset LD_PRELOAD LD_LIBRARY_PATH` — Yandex.Browser передаёт ребёнку nix-store-пути, и любой `sh`/`distrobox` падает с `GLIBC_2.38 not found`
- `export PATH=/etc/profiles/per-user/decard/bin:/run/current-system/sw/bin:/run/wrappers/bin:$PATH` — Yandex даёт пустой PATH, distrobox без него не находит coreutils
- `pgrep -x pcscd || sudo -n /usr/sbin/pcscd` внутри контейнера — лениво поднимаем pcscd при первом обращении

См. `~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge` — они идентичны кроме конечного `exec /opt/.../binary`.

### 7. NM-манифесты для Yandex.Browser

`~/.config/yandex-browser/NativeMessagingHosts/`:

| Файл | Бинарь, который через bridge | Расширение(я) |
|---|---|---|
| `ru.cryptopro.nmcades.json` | `nmcades-bridge` → `/opt/cprocsp/bin/amd64/nmcades` | `iifchhfnnmpdbibifmljnfjhpififfog`, `epebfcehmdedogndhlcacafjaacknbcm` |
| `kd.nc.json` | `kd-nc-bridge` → `/opt/diag.plugin/Diag.Plugin.nc` | 7 ID, среди них Контур.Плагин `momffihklfhkoakghidmkdocdkbfmoac` |
| `kontur.plugin.json` | `kontur-plugin-bridge` → `/opt/kontur.plugin/kontur.plugin.host` | 6 ID, среди них Контур.Плагин `momffihklfhkoakghidmkdocdkbfmoac` |

`allowed_origins` копировать **из контейнера** один-в-один, чтобы сохранить полный список расширений.

### 8. Расширения в Yandex.Browser

Установить из Opera Add-ons:
- **CryptoPro Extension for CAdES Browser Plug-in** (ID `epebfcehmdedogndhlcacafjaacknbcm`)
- **Контур.Плагин** (ID `momffihklfhkoakghidmkdocdkbfmoac`) — обычно ставится автоматически Контуром при первом заходе на check.kontur.ru

### 9. Проверка

- https://www.cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html — должно показать «Плагин загружен», версии, и список сертификатов из uMy
- https://help.kontur.ru/check (или https://check.kontur.ru) — диагностика Контура должна найти Контур.Плагин и сертификаты
- Реальный тест: войти в Точку и подписать документ; войти в Диадок и подписать документ

## Известные грабли (с которыми реально столкнулись)

- **Хостовый pcscd мешает токену.** Если включить `services.pcscd.enable = true` на хосте, он берёт устройство по libusb и падает на `LIBUSB_ERROR_ACCESS`, циклически отпуская — токен «моргает» и недоступен изнутри контейнера. **Не включать.**
- **MODE=0664 + uaccess недостаточно.** Внутри distrobox sudo даёт mapped-root (subuid `~100000`), у него нет ACL от `uaccess`. Нужен `MODE=0666`.
- **Rutoken Lite ≠ HID.** Класс USB-интерфейса 0x0b — это CCID. `libccid 1.7.1` уже знает VID `0x0A89` (1274 поддерживаемых VID/PID), `pcsc_scan` видит токен с ATR `Rutokenlite`. Отдельный `ifd-rutokens` ставить **не обязательно**, но не помешает.
- **Cades plug-in 2.0.15003 → 2.0.15600.** Tarball `linux-amd64_deb.tgz` идёт с `cprocsp-pki-cades-64_2.0.15003-1`. Это устарело — берём свежий `cades-linux-amd64.tar.gz` со страницы плагина и накатываем поверх.
- **Кнопка «Установить корневой сертификат ФНС» через apt-get install -fy.** Контурские пакеты ловятся на post-install (`systemctl` без systemd) и могут оставить `kontur.plugin/kontur.updater` в state `rH` (removed half-installed). **Не запускать `apt-get install -fy` если в системе есть kontur-пакеты.** Ставить только конкретные `.deb` через `dpkg -i`.
- **Manifest V2 в Chrome 147 мёртв.** Расширение CryptoPro Cades только MV2, удалено из Web Store, policy `ExtensionManifestV2Availability` убрана в Chrome 139, Developer-mode unpacked тоже не загрузит. Yandex.Browser — единственный практичный путь.
- **Yandex от miuirussia/yandex-browser.nix передаёт ребёнку LD_LIBRARY_PATH.** Любой child-процесс пытается слинковаться с nix-store-libs и падает на mismatched glibc. Bridge должен делать `unset LD_LIBRARY_PATH LD_PRELOAD` первым делом.
- **`#!/usr/bin/env bash` в bridge ломается** под Yandex (PATH=`/usr/bin:/bin`, bash там нет). Использовать `#!/bin/sh`.
- **distrobox-export Yandex.Browser → нативный Yandex.Browser.** Когда переходишь от distrobox-Yandex (где browser живёт ВНУТРИ контейнера и видит `/opt/...` напрямую) к нативному Yandex (на хосте), пути в NM-манифестах нужно поменять с `/opt/.../binary` на `/home/decard/.local/bin/*-bridge`.

## Maintenance

**Обновление КриптоПро CSP / Cades plug-in:** скачать новый tarball, `tar xzf`, `dpkg -i` нужные `.deb`-ы внутри контейнера. Bridge не трогать.

**Обновление Контур.Плагин:** в норме `kontur.updater` сделает это сам через свой systemd timer — но в контейнере без systemd timer не работает. Ручной апдейт: скачать с https://help.kontur.ru/plugin/linux, dpkg -i (помня про systemctl-stub перед установкой).

**Срок сертификата токена.** Текущий до 2027-01-13. Перед концом срока — получить новый сертификат у УЦ ФНС, записать на тот же токен, установить в uMy через `certmgr -inst -store uMy -cont '...'`.

**Если Yandex.Browser не видит провайдера:** `tail ~/.cache/{nmcades,kd-nc,kontur-plugin}-bridge.log`. Самые частые сообщения:
- `distrobox: not found` → bridge запустили без правильного PATH (см. выше)
- `GLIBC_2.X not found` → bridge запустили без `unset LD_LIBRARY_PATH`
- `/lib/x86_64-linux-gnu/libc.so.6: not found by ld-linux` → то же
- `pcscd not running` или сертификаты пустые → токен не вставлен / `MODE=0666` не применилось / переткнуть токен
