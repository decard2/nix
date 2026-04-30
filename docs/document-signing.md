# Подпись документов российским КЭП на NixOS (native)

Рабочая нативная схема подписи в Точке Банк, Контур.Диадок и других веб-сервисах
аппаратным ключом Aktiv Rutoken Lite. Без Windows VM, без distrobox, без
proprietary FHS-контейнера. Всё деклартивно через NixOS-конфиг.

## Что используется

- **Токен:** Aktiv Rutoken Lite (USB, VID:PID `0a89:0025`).
- **Криптопровайдер:** КриптоПро CSP 5.0.13003-7 (proprietary deb).
- **Browser plugin:** КриптоПро ЭЦП Browser plug-in 2.0.15600 (Cades).
- **Контур:** kontur.plugin 4.13.0.4561 + Diag.Plugin 3.1.2.425.
- **Браузер:** Yandex.Browser (Chromium-derivative).
- **Reader daemon:** pcscd с libccid (NixOS service).

## Архитектура

```
┌────────────────────────────────────────────────┐
│ Yandex.Browser                                 │
│ ├─ extension iifchhf...mpdbibifmljnf... (Cades)│
│ ├─ extension hnhppcg...gejeffnbnio... (Kontur) │
│ └─ extension inlmamah...cfioibldbpb... (Diag)  │
└────────────────┬───────────────────────────────┘
                 │ chrome.runtime.connectNative()
                 ▼
┌────────────────────────────────────────────────┐
│ Native Messaging hosts (3 manifests × 3 dirs)  │
│ /etc/{chromium,opt/chrome,opt/yandex/browser}/ │
│   native-messaging-hosts/                      │
│   ├─ ru.cryptopro.nmcades.json → nmcades-proxy │
│   ├─ kontur.plugin.json        → kontur.host   │
│   └─ kd.nc.json                → Diag.Plugin.nc│
└────────┬──────────────┬────────────────────────┘
         │              │
         ▼              ▼
┌──────────────────┐  ┌──────────────────────────┐
│ nmcades-proxy.py │  │ kontur.plugin.host       │
│ (writePython3)   │  │ Diag.Plugin.nc           │
│ перехват         │  └────────┬─────────────────┘
│ approved_site    │           │
│ + zenity diag    │           │
└────────┬─────────┘           │
         │ stdin/stdout        │
         ▼                     ▼
┌────────────────────────────────────────────────┐
│ /opt/cprocsp/bin/amd64/nmcades                 │
│ libcades.so + libpkivalidator.so + librevprov  │
│ libcsp.so (KC1, GOST 34.10-2012)               │
└──────────┬─────────────────────────────────────┘
           │ /opt/cprocsp/lib/amd64/librdrpcsc.so
           ▼
┌────────────────────────────────────────────────┐
│ pcscd (system service, ccid plugin)            │
│ /run/pcscd/pcscd.comm                          │
└──────────┬─────────────────────────────────────┘
           │ libccid → /dev/bus/usb/...
           ▼
        Rutoken Lite (USB)
```

## Что лежит в репо

- `system/services/smartcard.nix` — единственный конфиг-файл всей подписи:
  - `cryptoproCsp` (монолит CSP+Cades), `konturPlugin`, `diagPlugin`
  - `nmcadesProxy` (Python-обёртка)
  - все NM-host JSONы
  - `services.pcscd.enable`, `services.udev.extraRules` для USB-токена
  - `systemd.tmpfiles.rules` для `/opt/cprocsp`, `/var/opt/cprocsp/*`,
    `/etc/opt/skbkontur/plugin`, `/var/tmp/skbkontur/plugin/metrics`
  - `system.activationScripts.cprocspSetup` — postinst-replication
    (cpconfig провайдеры, KeyDevices, KeyCarriers, apppath, OIDs, лицензии,
    bulk-install CA в uRoot/uCA + mRoot/mCA)
- `system/network.nix` — sing-box bypass для РФ-доменов подписи:
  `tax.gov.ru`, `nalog.ru`, `reestr-pki.ru`, `cryptopro.ru`, `kontur.ru`,
  `kontur-extern.ru`, `kontur-ca.ru`, `tochka.com`.

## Установка с нуля

### 1. Скачать .deb пакеты вручную (EULA-walled)

Все proprietary архивы загружаются через `pkgs.requireFile` — пользователь
кладёт файлы в nix-store через `nix-store --add-fixed`.

```fish
# КриптоПро CSP
# Зайти на https://cryptopro.ru/products/csp/downloads (нужна регистрация),
# скачать "КриптоПро CSP для Linux (x64, deb)":
nix-store --add-fixed sha256 ~/Downloads/linux-amd64_deb.tgz

# КриптоПро ЭЦП Browser plug-in
# https://cryptopro.ru/products/cades/plugin → "Linux (deb)":
nix-store --add-fixed sha256 ~/Downloads/cades-linux-amd64.tar.gz

# ФНС-2024_01 (промежуточный CA для ИП-сертификатов 2025 выпуска).
# pki.tax.gov.ru недоступен через VPN/sing-box — отключить proxy перед скачиванием.
sudo systemctl stop sing-box
curl -fSLo ~/Downloads/ca_fns_russia_2024_01.crt \
  http://pki.tax.gov.ru/crt/ca_fns_russia_2024_01.crt
sudo systemctl start sing-box
nix-store --add-fixed sha256 ~/Downloads/ca_fns_russia_2024_01.crt
```

Контур.Плагин и Diag.Plugin скачиваются автоматически через `pkgs.fetchurl`
(CDN api.kontur.ru — публичный).

### 2. Применить конфиг

```fish
sudo nixos-rebuild switch --flake .#emerald
```

При первом switch'e activation script:

- создаст `/opt/cprocsp` symlink в nix-store
- скопирует skeleton `/var/opt/cprocsp/` (stores, dsrf)
- зарегистрирует все провайдеры/ридеры через cpconfig
- установит все CA из `tmpcerts/` + Минцифры-2022 + ФНС-2024 в `uRoot`/`uCA`
  (под decard через runuser) и `mRoot`/`mCA` (под root)

### 3. Удалить user-shadow NM-host JSONы (если переходишь с distrobox)

User-level NM-host имеет приоритет над system-level. Если в
`~/.config/<browser>/NativeMessagingHosts/` остались старые манифесты
от distrobox-bridges — браузер не увидит наши system-wide.

```fish
rm -f ~/.config/yandex-browser/NativeMessagingHosts/{kd.nc,kontur.plugin,ru.cryptopro.nmcades}.json
rm -f ~/.config/google-chrome/NativeMessagingHosts/ru.cryptopro.nmcades.json
rm -f ~/.config/chromium/NativeMessagingHosts/ru.cryptopro.nmcades.json
rm -f ~/.local/bin/{kontur-plugin,nmcades,kd-nc}-bridge
```

### 4. Воткнуть токен и проверить

```fish
sudo -u decard /opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -fqcn -verifycontext
# должны увидеть контейнеры '\\.\Aktiv Rutoken lite 00 00\<NNN>@<DATE>-<NAME>'

sudo -u decard /opt/cprocsp/bin/amd64/certmgr -list -store uMy
# должны увидеть свои сертификаты с привязкой Container/Provider

# Открыть https://cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html
# в Yandex.Browser → выбрать сертификат → "Подписать данные"
# Цепочка должна показать 3 уровня (твой → УЦ ФНС → НУЦ Минцифры),
# Статус: Действителен.
```

## Грабли

### "PluginException 0x6C: available directory not found"

`kontur.plugin.host` падает при старте. Postinst kontur.plugin.deb создаёт
два каталога:

```
/etc/opt/skbkontur/plugin
/var/tmp/skbkontur/plugin/metrics
```

Без них хост крашится с этим exception, browser показывает "плагин не виден".
В нашем конфиге создаются через `systemd.tmpfiles.rules`.

### nmcades висит на approved_site

При первом запросе подписи плагин КриптоПро запрашивает у browser-extension
проверку "trusted site". На NixOS msz-конфиг trusted_sites битый, nmcades
ждёт ответ бесконечно. Решено через `nmcadesProxy` (Python writePython3) —
проксирует stdin/stdout, перехватывает `approved_site`, ведёт свой список
в `~/.config/cryptopro-trusted-sites`, для unknown показывает zenity-диалог.

### "Status: Не действителен" (длинный таймаут)

Cades plugin не может построить цепочку или скачать CRL/OCSP. Причины:

1. **Промежуточный CA отсутствует в uCA**. Сертификаты ИП 2025 выпуска
   подписаны "УЦ ФНС России 2024_01" — этого CA в `lsb-cprocsp-ca-certs.deb`
   tmpcerts нет. Решено через `pkgs.requireFile ca_fns_russia_2024_01.crt`.
2. **VPN/sing-box режет CRL/OCSP-fetch**. Cades ходит на `pki.tax.gov.ru`,
   `cdp.tax.gov.ru`, `reestr-pki.ru` — эти домены должны идти через `direct`,
   не через VLESS-прокси. Bypass-rule в `system/network.nix`.

### "Inert carrier rutoken"

CSP видит токен, но не может прочитать контейнер. Возможные причины:

- В системе крутится **второй** pcscd (например `/usr/sbin/pcscd` от
  distrobox-эпохи). Держит токен в exclusive transaction, второй pcscd не
  может работать. Убить старый: `sudo kill <PID>`.
- Запущен `podman tochka` контейнер (старый distrobox). Остановить и
  удалить: `podman stop tochka && podman rm tochka`.

### Browser не видит плагин после rebuild'a

Закрыть Yandex.Browser **полностью** (`pkill -f yandex-browser`) — он
кэширует список NM-host'ов при старте. После перезапуска подхватит свежие
JSONы из `/etc/opt/yandex/browser/native-messaging-hosts/`.

### CA в machine-store пустой

Cades plugin запускается из user-context и читает **uRoot/uCA**, не
**mRoot/mCA**. Поэтому activation script ставит CA в обе пары (через
`runuser -u decard` и через root напрямую) — uRoot/uCA для browser-плагинов,
mRoot/mCA для CLI/system-инструментов.

## Связанные документы

- `docs/research/cryptopro-kontur-native-packaging.md` — research-документ
  перед миграцией с distrobox; содержит сравнение подходов
  (autoPatchelfHook vs buildFHSEnv vs nix-ld) и шаблоны derivation'ов.
- `docs/research/yandex-browser-nixos.md` — research по упаковке
  Yandex.Browser на NixOS и определению путей NM-host'ов.

## Референсы

- [sakost/nixos](https://github.com/sakost/nixos/blob/master/packages/cryptopro-csp.nix)
  — рабочий public NixOS-конфиг CryptoPro CSP. Главный референс при отладке;
  паттерн монолита, nmcades-proxy, mass-CA-install — заимствованы оттуда.
- [SomeoneSerge/pkgs cprocsp](https://github.com/SomeoneSerge/pkgs/tree/master/pkgs/by-name/cp/cprocsp)
  — академический пример декомпозиции CSP по 30+ компонентам.
- [msva/mva-overlay](https://github.com/msva/mva-overlay) (Gentoo) —
  документирует `/opt/kontur.plugin/pkcs11` segfault и сегментацию путей.
