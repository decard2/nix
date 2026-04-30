{ pkgs, lib, ... }:
let
  # Монолит CSP + Cades (как у sakost). Распаковываются в один $out, чтобы
  # /opt/cprocsp/lib/amd64/ содержал ВСЕ libs обоих пакетов. Без этого
  # nmcades/CSP делают dlopen("libcades.so") по стандартному пути и не
  # находят его, потому что cades-libs физически в другом nix-store
  # каталоге → "inert carrier" при операции подписи.
  cadesArchive = pkgs.requireFile {
    name = "cades-linux-amd64.tar.gz";
    hash = "sha256-0+XYOVwhgZmTw4Q4fiamVZp6CTyUwikmIDoBdp9Px54=";
    message = ''
      КриптоПро ЭЦП Browser plug-in — ручная загрузка.
      1. https://cryptopro.ru/products/cades/plugin (нужна регистрация на cryptopro.ru)
      2. Скачать "Linux (deb)" — файл cades-linux-amd64.tar.gz
      3. nix-store --add-fixed sha256 cades-linux-amd64.tar.gz
      4. nix hash file cades-linux-amd64.tar.gz
    '';
  };

  cryptoproCsp = pkgs.stdenv.mkDerivation {
    pname = "cprocsp";
    version = "5.0.13003-7";

    src = pkgs.requireFile {
      name = "linux-amd64_deb.tgz";
      hash = "sha256-oM/0hvv2D3a2HTUnSUWzAuUyfQ8SY+RlrU09Kj1f+rQ=";
      message = ''
        КриптоПро CSP требует ручной загрузки.

        1. Зайти на https://cryptopro.ru/products/csp/downloads
        2. Зарегистрироваться (бесплатно) и залогиниться
        3. Скачать "КриптоПро CSP для Linux (x64, deb)" — файл linux-amd64_deb.tgz
        4. nix-store --add-fixed sha256 linux-amd64_deb.tgz
        5. nix hash file linux-amd64_deb.tgz   # положить вывод в hash выше
      '';
    };

    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      pcsclite
      gtk3
      cairo
      glib
      pango
      harfbuzz
      atk
      gdk-pixbuf
      openssl
      stdenv.cc.cc.lib
    ];

    # autoPatchelfHook не ходит сам в opt/cprocsp/lib/amd64 — приходится
    # вручную добавить, чтобы он мог разрешить cross-references между
    # CSP-libs и cades-libs распакованными в один $out.
    preFixup = ''
      addAutoPatchelfSearchPath $out/opt/cprocsp/lib/amd64
    '';

    unpackPhase = ''
      runHook preUnpack
      mkdir -p source
      tar xzf $src -C source
      tar xzf ${cadesArchive} -C source
      runHook postUnpack
    '';

    buildPhase = ''
      runHook preBuild
      mkdir -p extracted
      # debs из основной CSP-tarball + 2 deba из cades-tarball — все в один
      # extracted/, чтобы итоговый $out имел ВСЕ libs в общем lib/amd64/.
      for pattern in \
        lsb-cprocsp-base \
        lsb-cprocsp-rdr-64 \
        lsb-cprocsp-kc1-64 \
        lsb-cprocsp-capilite-64 \
        cprocsp-rdr-rutoken-64 \
        cprocsp-rdr-pcsc-64 \
        cprocsp-rdr-gui-gtk-64 \
        lsb-cprocsp-pkcs11-64 \
        lsb-cprocsp-ca-certs \
        cprocsp-pki-cades-64 \
        cprocsp-pki-plugin-64 \
      ; do
        for deb in source/linux-amd64_deb/$pattern*.deb source/cades-linux-amd64/$pattern*.deb; do
          [ -f "$deb" ] && dpkg-deb -x "$deb" extracted
        done
      done
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt $out/
      cp -a extracted/etc $out/ 2>/dev/null || true
      cp -a extracted/var $out/ 2>/dev/null || true
      runHook postInstall
    '';

    dontStrip = true;
  };

  konturPlugin = pkgs.stdenv.mkDerivation {
    pname = "kontur-plugin";
    version = "4.13.0.4561";

    src = pkgs.fetchurl {
      url = "https://api.kontur.ru/drive/v1/public/diag/files/kontur.plugin.002875.deb";
      hash = "sha256-k6wRzEQHx8v0551/HuJpOPimVneAfQuB34ncqG6JrfY=";
    };

    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      cryptoproCsp
      gtk3
      cairo
      glib
      openssl
      stdenv.cc.cc.lib
    ];

    # autoPatchelfHook ищет libs только в стандартных lib/ путях buildInputs.
    # CryptoPro кладёт shared-libs в нестандартный opt/cprocsp/lib/amd64 —
    # надо явно добавить этот путь в search-path для autoPatchelf.
    preFixup = ''
      addAutoPatchelfSearchPath ${cryptoproCsp}/opt/cprocsp/lib/amd64
    '';

    # appendRunpaths для рантайма: kontur.plugin.host dlopen()-ит CSP-libs.
    # `runtimeDependencies = [ cryptoproCsp ]` бы добавило ${cryptoproCsp}/lib —
    # пустой каталог, поэтому идём через явный путь.
    appendRunpaths = [ "${cryptoproCsp}/opt/cprocsp/lib/amd64" ];

    unpackPhase = ''
      runHook preUnpack
      mkdir extracted
      dpkg-deb -x "$src" extracted
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt $out/
      # CRITICAL (research/cryptopro-kontur-native-packaging.md):
      # /opt/kontur.plugin/pkcs11/ triggers a segfault inside the host plugin.
      rm -rf $out/opt/kontur.plugin/pkcs11
      runHook postInstall
    '';

    dontStrip = true;
  };

  diagPlugin = pkgs.stdenv.mkDerivation {
    pname = "diag-plugin";
    version = "3.1.2.425";

    src = pkgs.fetchurl {
      # Stable redirect: https://help.kontur.ru/files/diag.plugin_amd64.deb →
      # this versioned file in api.kontur.ru drive. Filename is
      # `diag.plugin_amd64_signed.<build>.deb` (not `diag.plugin.<build>.deb`).
      url = "https://api.kontur.ru/drive/v1/public/diag/files/diag.plugin_amd64_signed.002623.deb";
      hash = "sha256-wdk2EQsSXQWN801nalzZYBKSlJdW0m5jg2ef5gA8fCI=";
    };

    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      cryptoproCsp
      gtk3
      glib
      cairo
      stdenv.cc.cc.lib
    ];

    # autoPatchelfHook ищет CSP-libs только в стандартных путях
    # buildInputs (типа $foo/lib). У cryptoproCsp libs лежат в
    # opt/cprocsp/lib/amd64 — расширяем search path вручную.
    preFixup = ''
      addAutoPatchelfSearchPath ${cryptoproCsp}/opt/cprocsp/lib/amd64
    '';

    # appendRunpaths — для рантайма (dlopen). Тот же путь, что и в preFixup.
    appendRunpaths = [ "${cryptoproCsp}/opt/cprocsp/lib/amd64" ];

    unpackPhase = ''
      runHook preUnpack
      mkdir -p extracted
      dpkg-deb -x "$src" extracted
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt $out/
      runHook postInstall
    '';

    dontStrip = true;
  };

  # CA-сертификаты нужны для chain validation подписанных ФНС сертификатов.
  # Без них cades возвращает "Status: Не действителен" — цепочка не строится
  # до корня. URLs и хэши взяты из sakost/nixos (рабочий референс).
  fnsCA2023 = pkgs.fetchurl {
    url = "http://pki.tax.gov.ru/crt/ca_fns_russia_2023_01.crt";
    hash = "sha256-frQlvE5yojoILBdntVqbl4oL+1+OxHLDCGMbB7QAgxw=";
  };
  mintsifryCA2022 = pkgs.fetchurl {
    url = "http://reestr-pki.ru/cdp/guc2022.crt";
    hash = "sha256-S7N8x8D/S/KqiT6VB267NWXGkjfuG2FjW+7kwZZklcc=";
  };
  # ФНС-2024 — нужен для сертификатов ИП выпуска 2025 (issuer = "УЦ ФНС
  # России 2024_01"). Сертификат в .deb tmpcerts отсутствует. Скачать через
  # fetchurl невозможно: pki.tax.gov.ru недоступен из-за sing-box VPN
  # proxy. Поэтому через requireFile — пользователь скачивает руками
  # (с отключённым VPN: `curl -fSLo ~/Downloads/ca_fns_russia_2024_01.crt
  # http://pki.tax.gov.ru/crt/ca_fns_russia_2024_01.crt`) и кладёт в store
  # через `nix-store --add-fixed sha256 ~/Downloads/ca_fns_russia_2024_01.crt`.
  fnsCA2024 = pkgs.requireFile {
    name = "ca_fns_russia_2024_01.crt";
    hash = "sha256-MoO0T8FkT66xIA3OBKBT6Ddt3K/8nR7GLlf7ptVZcqY=";
    message = ''
      Промежуточный CA УЦ ФНС России 2024_01 нужен вручную.

      1. Отключить VPN/sing-box (pki.tax.gov.ru недоступен через прокси).
      2. curl -fSLo ~/Downloads/ca_fns_russia_2024_01.crt \
           http://pki.tax.gov.ru/crt/ca_fns_russia_2024_01.crt
      3. nix hash file ~/Downloads/ca_fns_russia_2024_01.crt
      4. nix-store --add-fixed sha256 ~/Downloads/ca_fns_russia_2024_01.crt
    '';
  };

  # Native messaging proxy для nmcades.
  #
  # Без этого nmcades запрашивает у browser-extension'а "is_approved_site",
  # extension возвращает false (in-memory map пустой), nmcades потом проверяет
  # свой msz-конфиг trusted_sites — на NixOS он битый — и в результате висит
  # бесконечно (PluginException 0x0000006C "available directory not found").
  #
  # Прокси перехватывает approved_site, ведёт свой список доверенных origin'ов
  # в ~/.config/cryptopro-trusted-sites и спрашивает пользователя через zenity
  # для неизвестных. Точка/Диадок попадают в список после первого диалога.
  #
  # Код заимствован из github.com/sakost/nixos (commit 2026-02-21) — рабочий
  # референс CryptoPro CSP на NixOS.
  nmcadesProxy = pkgs.writers.writePython3 "nmcades-proxy" {
    flakeIgnore = [ "E401" "E501" ];
  } ''
    import struct, json, subprocess, os, sys, select, fcntl
    from urllib.parse import urlparse

    NMCADES = "${cryptoproCsp}/opt/cprocsp/bin/amd64/nmcades"
    LD_PATH = "${cryptoproCsp}/opt/cprocsp/lib/amd64"
    ZENITY = "${pkgs.zenity}/bin/zenity"
    TRUSTED_FILE = os.path.expanduser(
        "~/.config/cryptopro-trusted-sites"
    )


    def load_trusted():
        try:
            with open(TRUSTED_FILE) as f:
                return set(
                    line.strip() for line in f if line.strip()
                )
        except FileNotFoundError:
            return set()


    def save_site(site):
        os.makedirs(os.path.dirname(TRUSTED_FILE), exist_ok=True)
        with open(TRUSTED_FILE, "a") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            f.write(site + "\n")


    def site_origin(url):
        p = urlparse(url)
        return f"{p.scheme}://{p.netloc}" if p.netloc else url


    def is_trusted(url, trusted):
        origin = site_origin(url)
        for pattern in trusted:
            if pattern == origin:
                return True
            if pattern.startswith("https://*."):
                domain = pattern[len("https://*."):]
                host = urlparse(url).hostname or ""
                if host == domain or host.endswith("." + domain):
                    return True
            if pattern.startswith("http://*."):
                domain = pattern[len("http://*."):]
                host = urlparse(url).hostname or ""
                if host == domain or host.endswith("." + domain):
                    return True
        return False


    def ask_user(url):
        origin = site_origin(url)
        try:
            rc = subprocess.call([
                ZENITY, "--question",
                "--title=CryptoPro CAdES",
                "--text="
                f"Сайт <b>{origin}</b> запрашивает доступ "
                "к криптографическому плагину CryptoPro.\n\n"
                "Разрешить?",
                "--ok-label=Разрешить",
                "--cancel-label=Запретить",
                "--width=400",
            ])
            return rc == 0
        except Exception:
            return False


    env = {**os.environ, "LD_LIBRARY_PATH": LD_PATH}
    try:
        proc = subprocess.Popen(
            [NMCADES] + sys.argv[1:],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            env=env,
        )
    except OSError:
        sys.exit(1)

    stdin_fd = sys.stdin.buffer
    stdout_fd = sys.stdout.buffer


    def read_msg(stream):
        raw = stream.read(4)
        if not raw or len(raw) < 4:
            return None
        length = struct.unpack("<I", raw)[0]
        data = stream.read(length)
        if len(data) < length:
            return None
        return json.loads(data)


    def write_msg(stream, msg):
        data = json.dumps(msg, separators=(",", ":")).encode("utf-8")
        stream.write(struct.pack("<I", len(data)))
        stream.write(data)
        stream.flush()


    trusted_sites = load_trusted()

    try:
        while proc.poll() is None:
            readable, _, _ = select.select(
                [stdin_fd, proc.stdout], [], [], 1.0
            )
            for fd in readable:
                if fd is stdin_fd:
                    msg = read_msg(stdin_fd)
                    if msg is None:
                        proc.terminate()
                        sys.exit(0)
                    write_msg(proc.stdin, msg)
                elif fd is proc.stdout:
                    msg = read_msg(proc.stdout)
                    if msg is None:
                        sys.exit(0)
                    dtype = msg.get("data", {}).get("type", "")
                    if dtype == "approved_site":
                        value = msg.get("data", {}).get("value", "")
                        if value.startswith("is_approved_site:"):
                            url = value[len("is_approved_site:"):].lstrip()
                            approved = is_trusted(url, trusted_sites)
                            if not approved:
                                approved = ask_user(url)
                                if approved:
                                    origin = site_origin(url)
                                    trusted_sites.add(origin)
                                    save_site(origin)
                            resp = {
                                **msg,
                                "data": {
                                    **msg["data"],
                                    "params": [{"type": "boolean", "value": approved}],
                                },
                            }
                            write_msg(proc.stdin, resp)
                            continue
                    write_msg(stdout_fd, msg)
    except (BrokenPipeError, OSError):
        pass
    finally:
        proc.terminate()
  '';

  # Общий JSON-объект NM-host для nmcades, чтобы дублировать в 3 каталога.
  nmcadesNmHost = builtins.toJSON {
    name = "ru.cryptopro.nmcades";
    description = "CryptoPro CAdES Browser plug-in";
    # Browser запускает прокси-обёртку, которая внутри стартует nmcades из
    # ${cryptoproCsp} (после слияния cades в монолит).
    path = "${nmcadesProxy}";
    type = "stdio";
    allowed_origins = [
      "chrome-extension://iifchhfnnmpdbibifmljnfjhpififfog/"
      "chrome-extension://epebfcehmdedogndhlcacafjaacknbcm/"
    ];
  };
  diagNmHost = builtins.toJSON {
    name = "kd.nc";
    description = "Diag.Plugin Native Messaging Host";
    path = "${diagPlugin}/opt/diag.plugin/Diag.Plugin.nc";
    type = "stdio";
    allowed_origins = [
      "chrome-extension://inlmamahcfioibldbpbaechbpeeaelin/"
      "chrome-extension://pioommjcfaefbcpbdokfoadjhlmahjjm/"
      "chrome-extension://adipnhhjfmoehhkepljbifddkobenooa/"
      "chrome-extension://fmdmnjcgegbabdefddkijefeadkhchcn/"
      "chrome-extension://momffihklfhkoakghidmkdocdkbfmoac/"
      "chrome-extension://kbeplgmhdbgnbpfkcmndbhjfadkhinhn/"
      "chrome-extension://nhbmmgegnhdhkcclaandbaipceebnckc/"
    ];
  };
  konturNmHost = builtins.toJSON {
    name = "kontur.plugin";
    description = "Kontur.Plugin";
    path = "${konturPlugin}/opt/kontur.plugin/kontur.plugin.host";
    type = "stdio";
    allowed_origins = [
      "chrome-extension://hnhppcgejeffnbnioloohhmndpmclaga/"
      "chrome-extension://nejicfcnfnecdilmajlppdcgbjilgeec/"
      "chrome-extension://akpjpngckapnibajopggmfhnchfpnkkf/"
      "chrome-extension://momffihklfhkoakghidmkdocdkbfmoac/"
      "chrome-extension://kbeplgmhdbgnbpfkcmndbhjfadkhinhn/"
      "chrome-extension://nhbmmgegnhdhkcclaandbaipceebnckc/"
    ];
  };
in {
  # Aktiv Co. — Rutoken family. MODE=0666 нужен потому что ранее требовался
  # mapped-root в distrobox; на нативном хосте `0664` + `uaccess` тоже бы
  # хватило, но 0666 универсально и не несёт риска (токен физически в твоей
  # машине). Оставляем как было.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0a89", MODE="0666"
  '';

  # Host pcscd (host-level, not in container).
  # Был выключен раньше потому что distrobox с пользовательскими процессами
  # внутри запускал свой pcscd, который дрался с хостовым за USB. Теперь
  # distrobox уходит → конфликта нет, pcscd на хосте — единственный владелец.
  services.pcscd.enable = true;
  services.pcscd.plugins = [ pkgs.ccid ];

  systemd.tmpfiles.rules = [
    # /opt/cprocsp = symlink в nix-store (immutable). kontur.plugin.host
    # жёстко читает /opt/cprocsp/sbin/amd64/cpconfig, csptest и др. тоже
    # работают с этим префиксом.
    "L+ /opt/cprocsp 0755 root root - ${cryptoproCsp}/opt/cprocsp"

    # /var/opt/cprocsp — mutable per-host state. Полностью инициализируется из
    # nix-store activation-скриптом (cp -rn). Здесь только одна tmpfiles-rule
    # для пути, она на самом деле не нужна (cp создаст), но оставляем чтобы
    # systemd-tmpfiles прогнал sticky-bit на /var/opt/cprocsp/users.
    "d  /var/opt/cprocsp                   0755 root   root  -"
    # 1777 = sticky world-writable (как /tmp). Нужно потому что CryptoPro
    # лениво создаёт /var/opt/cprocsp/users/<username>/ при первом
    # certmgr/csptest-вызове, а имя берётся из getpwuid → 'decard', не UID.
    "d  /var/opt/cprocsp/users             1777 root   root  -"

    # /etc/opt/cprocsp — writable copy дефолтного config64.ini делает
    # activation-скрипт (cp если файла нет).
    "d  /etc/opt/cprocsp                   0755 root   root  -"

    # cpconfig пишет lock-файлы в /var/opt/cprocsp/tmp; без него -hardware
    # reader -add бесконечно ретраит O_CREAT|O_EXCL.
    "d  /var/opt/cprocsp/tmp               1777 root   root  -"

    # Контур.Плагин postinst создаёт эти каталоги. Без них kontur.plugin.host
    # падает на старте с `PluginException 0x6C: available directory not found`,
    # browser-extension получает Aborted при connectNative() и в UI рисует
    # "плагин не виден". plugin_settings.json внутри хост создаёт сам
    # при первом успешном запуске — нужно только существование самой папки.
    "d  /etc/opt/skbkontur                 0755 root   root  -"
    "d  /etc/opt/skbkontur/plugin          0755 root   root  -"
    "d  /var/tmp/skbkontur                 0777 root   root  -"
    "d  /var/tmp/skbkontur/plugin          0777 root   root  -"
    "d  /var/tmp/skbkontur/plugin/metrics  0777 root   root  -"
  ];

  system.activationScripts.cprocspSetup = lib.stringAfter [ "etc" ] ''
    # 0. Заполнить /var/opt/cprocsp скелетом из nix-store (один раз).
    #    cp -rn (no-clobber): не перетирает уже существующее, поэтому пользовательские
    #    данные в keys/ и users/ выживают rebuild'ы.
    cp -rn ${cryptoproCsp}/var/opt/cprocsp/. /var/opt/cprocsp/
    # global.ini в nix-store readonly (mode 444). cpconfig может его обновлять —
    # даём 644 на копии.
    chmod 644 /var/opt/cprocsp/users/global.ini 2>/dev/null || true

    # 1. Скопировать дефолтный config64.ini из nix-store, ЕСЛИ его ещё нет.
    #    Без этого cpconfig создаст minimal stub без описаний провайдеров/ридеров,
    #    и csptest будет падать на 0x8009001d (Provider DLL init).
    if [ ! -f /etc/opt/cprocsp/config64.ini ]; then
      cp ${cryptoproCsp}/etc/opt/cprocsp/config64.ini /etc/opt/cprocsp/config64.ini
      chmod 0644 /etc/opt/cprocsp/config64.ini
    fi

    # 2. autoPatchelfHook переписал PT_INTERP / RPATH в CSP-бинарях, из-за чего
    #    CSP self-integrity check падает: csptest и cpconfig сами по себе мрут
    #    на «Integrity check failed». DisableIntegrity=true отключает проверку.
    #    Идемпотентно — просто перезаписывает значение.
    ${cryptoproCsp}/opt/cprocsp/sbin/amd64/cpconfig -ini \
      '\config\parameters\protect_csp' -add string DisableIntegrity true \
      >/dev/null 2>&1 || true

    # 3. Регистрация провайдеров / считывателей / источников ГСЧ.
    #    Шаблонный config64.ini из .deb имеет ПУСТУЮ секцию [Defaults\Provider]
    #    (только комментарии). Список провайдеров наполняется postinst-скриптами
    #    каждого .deb (lsb-cprocsp-rdr-64, lsb-cprocsp-kc1-64, ...). Мы извлекали
    #    debs через `dpkg-deb -x` (только data.tar), поэтому postinst НЕ запускался.
    #    Реплицируем нужные cpconfig-вызовы здесь.
    #
    #    Все вызовы идемпотентны: cpconfig -add при повторе либо тихо ничего
    #    не делает, либо ругается ненулевым кодом — '|| true' нас защищает.

    CPCONFIG=${cryptoproCsp}/opt/cprocsp/sbin/amd64/cpconfig
    LIBDIR=${cryptoproCsp}/opt/cprocsp/lib/amd64
    SBINDIR=${cryptoproCsp}/opt/cprocsp/sbin/amd64

    register_provider() {
      local type="$1" name="$2"
      "$CPCONFIG" -ini "\\cryptography\\Defaults\\Provider\\$name" -add string 'Image Path'         "$LIBDIR/libcsp.so"             >/dev/null 2>&1 || true
      "$CPCONFIG" -ini "\\cryptography\\Defaults\\Provider\\$name" -add string 'Function Table Name' CPCSP_GetFunctionTable          >/dev/null 2>&1 || true
      "$CPCONFIG" -ini "\\cryptography\\Defaults\\Provider\\$name" -add long   Type "$type"                                          >/dev/null 2>&1 || true
    }

    # --- lsb-cprocsp-rdr-64 postinst: apppath, FLASH KeyDevice, CPSD random source, license
    "$CPCONFIG" -ini '\config\apppath' -add string libcapi10.so   "$LIBDIR/libcapi10.so"   >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string librdrfat12.so "$LIBDIR/librdrfat12.so" >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string librdrdsrf.so  "$LIBDIR/librdrdsrf.so"  >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string libcpui.so     "$LIBDIR/libcpui.so"     >/dev/null 2>&1 || true
    LIBCURL=$(${pkgs.glibc.bin}/bin/ldconfig -p 2>/dev/null | ${pkgs.gawk}/bin/awk '/libcurl\.so / {print $NF; exit}')
    "$CPCONFIG" -ini '\config\apppath' -add string libcurl.so "''${LIBCURL:-${pkgs.curl.out}/lib/libcurl.so}" >/dev/null 2>&1 || true

    "$CPCONFIG" -ini '\config\apppath' -add string mount_flash.sh "$SBINDIR/mount_flash.sh" >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\FLASH' -add string DLL librdrfat12.so      >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\FLASH' -add string Script mount_flash.sh   >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\FLASH' -add long Group 1                   >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\FLASH\PNP FLASH\Default' -add string Name 'All FLASH readers' >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\FLASH\PNP FLASH\Default\Name' -delparam    >/dev/null 2>&1 || true

    "$CPCONFIG" -hardware rndm -add CPSD -name 'CPSD RNG' -level 3 >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\Random\CPSD\Default' -add string '/db1/kis_1' /var/opt/cprocsp/dsrf/db1/kis_1 >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\Random\CPSD\Default' -add string '/db2/kis_1' /var/opt/cprocsp/dsrf/db2/kis_1 >/dev/null 2>&1 || true

    # Лицензия — демо-ключ из postinst (5050N-...). cpconfig -license -view сам
    # вернёт 0 если уже что-то стоит, тогда -set не выполнится.
    "$CPCONFIG" -license -view >/dev/null 2>&1 \
      || "$CPCONFIG" -license -set 5050N-40030-01BT7-2MA83-QF3T0 -use_expired >/dev/null 2>&1 \
      || true

    # --- lsb-cprocsp-kc1-64 postinst: providers (КЛЮЧЕВОЕ — без них csptest падает)
    "$CPCONFIG" -ini '\config\apppath' -add string librdrrndmbio_tui.so "$LIBDIR/librdrrndmbio_tui.so" >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string libcsp.so            "$LIBDIR/libcsp.so"            >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\Random\Bio_tui' -add string DLL librdrrndmbio_tui.so >/dev/null 2>&1 || true

    "$CPCONFIG" -hardware reader -add hdimage -name 'HDD key storage'        >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware rndm   -add bio_tui -name 'Text bio random' -level 5 >/dev/null 2>&1 || true

    # Дефолтный провайдер для каждого типа. Должен идти до register_provider —
    # cpconfig сам создаст секцию.
    "$CPCONFIG" -defprov -setdef -provtype 75 -provname 'Crypto-Pro GOST R 34.10-2001 KC1 CSP'        >/dev/null 2>&1 || true
    "$CPCONFIG" -defprov -setdef -provtype 80 -provname 'Crypto-Pro GOST R 34.10-2012 KC1 CSP'        >/dev/null 2>&1 || true
    "$CPCONFIG" -defprov -setdef -provtype 81 -provname 'Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP' >/dev/null 2>&1 || true
    "$CPCONFIG" -defprov -setdef -provtype 1  -provname 'Crypto-Pro RSA Cryptographic Service Provider' >/dev/null 2>&1 || true
    "$CPCONFIG" -defprov -setdef -provtype 16 -provname 'Crypto-Pro ECDSA and AES KC1 CSP'            >/dev/null 2>&1 || true
    "$CPCONFIG" -defprov -setdef -provtype 24 -provname 'Crypto-Pro Enhanced RSA and AES KC1 CSP'     >/dev/null 2>&1 || true
    "$CPCONFIG" -defprov -setdef -provtype 32 -provname 'Crypto-Pro Curve25519 and AES KC1 CSP'       >/dev/null 2>&1 || true

    register_provider 75 'Crypto-Pro GOST R 34.10-2001 KC1 CSP'
    register_provider 75 'Crypto-Pro GOST R 34.10-2001 Cryptographic Service Provider'
    register_provider 80 'Crypto-Pro GOST R 34.10-2012 KC1 CSP'
    register_provider 80 'Crypto-Pro GOST R 34.10-2012 Cryptographic Service Provider'
    register_provider 81 'Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP'
    register_provider 81 'Crypto-Pro GOST R 34.10-2012 Strong Cryptographic Service Provider'
    register_provider 1  'Crypto-Pro RSA Cryptographic Service Provider'
    register_provider 16 'Crypto-Pro ECDSA and AES KC1 CSP'
    register_provider 16 'Crypto-Pro ECDSA and AES CSP'
    register_provider 24 'Crypto-Pro Enhanced RSA and AES KC1 CSP'
    register_provider 24 'Crypto-Pro Enhanced RSA and AES CSP'
    register_provider 32 'Crypto-Pro Curve25519 and AES KC1 CSP'
    register_provider 32 'Crypto-Pro Curve25519 and AES CSP'

    for n in \
      'Crypto-Pro RSA Cryptographic Service Provider' \
      'Crypto-Pro ECDSA and AES KC1 CSP' \
      'Crypto-Pro ECDSA and AES CSP' \
      'Crypto-Pro Enhanced RSA and AES KC1 CSP' \
      'Crypto-Pro Enhanced RSA and AES CSP' \
      'Crypto-Pro Curve25519 and AES KC1 CSP' \
      'Crypto-Pro Curve25519 and AES CSP'; do
      "$CPCONFIG" -ini "\\config\\parameters\\$n" -add long KeyTimeValidityControlMode 128 >/dev/null 2>&1 || true
    done

    "$CPCONFIG" -ini '\cryptography\Defaults\Provider Types\Type 075' -add string TypeName "GOST R 34.10-2001 Signature with Diffie-Hellman Key Exchange"          >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\cryptography\Defaults\Provider Types\Type 080' -add string TypeName "GOST R 34.10-2012 (256) Signature with Diffie-Hellman Key Exchange"    >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\cryptography\Defaults\Provider Types\Type 081' -add string TypeName "GOST R 34.10-2012 (512) Signature with Diffie-Hellman Key Exchange"    >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\cryptography\Defaults\Provider Types\Type 001' -add string TypeName "RSA Full (Signature and Key Exchange)"                                 >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\cryptography\Defaults\Provider Types\Type 016' -add string TypeName "ECDSA Full and AES"                                                    >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\cryptography\Defaults\Provider Types\Type 024' -add string TypeName "RSA Full and AES"                                                      >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\cryptography\Defaults\Provider Types\Type 032' -add string TypeName "Curve25519 Full and AES"                                               >/dev/null 2>&1 || true

    # --- lsb-cprocsp-capilite-64 postinst: apppath
    "$CPCONFIG" -ini '\config\apppath' -add string libssp.so    "$LIBDIR/libssp.so"    >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string libcapi20.so "$LIBDIR/libcapi20.so" >/dev/null 2>&1 || true

    # --- lsb-cprocsp-pkcs11-64 postinst
    "$CPCONFIG" -ini '\config\apppath' -add string libcppkcs11.so "$LIBDIR/libcppkcs11.so" >/dev/null 2>&1 || true
    if ! "$CPCONFIG" -ini '\config\PKCS11' -enum section 2>/dev/null | grep -q '^slot0$'; then
      "$CPCONFIG" -ini '\config\PKCS11\slot0' -add string ProvGOST "" >/dev/null 2>&1 || true
      "$CPCONFIG" -ini '\config\PKCS11\slot0' -add string Firefox  "" >/dev/null 2>&1 || true
      "$CPCONFIG" -ini '\config\PKCS11\slot0' -add string reader   "" >/dev/null 2>&1 || true
    fi

    # --- cprocsp-rdr-pcsc-64 postinst: PC/SC reader + media (oscar/TRUST)
    "$CPCONFIG" -ini '\config\parameters' -add long dynamic_readers 1         >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\parameters' -add long dynamic_rdr_refresh_ms 1500 >/dev/null 2>&1 || true

    # NixOS не наполняет /etc/ld.so.cache, поэтому `ldconfig -p` пуст.
    # Не пытаемся искать libpcsclite через ldconfig — берём напрямую из nix-store.
    "$CPCONFIG" -ini '\config\apppath' -add string libpcsclite.so ${pkgs.pcsclite.lib}/lib/libpcsclite.so >/dev/null 2>&1 || true

    "$CPCONFIG" -ini '\config\apppath' -add string librdrpcsc.so "$LIBDIR/librdrpcsc.so" >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string librdrric.so  "$LIBDIR/librdrric.so"  >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\PCSC' -add string DLL librdrpcsc.so >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\PCSC' -add long Group 1            >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\PCSC\PNP PCSC\Default' -add string Name 'All PC/SC readers' >/dev/null 2>&1 || true
    # Явно прописываем libpcsclite.so путь в подсекцию PNP PCSC — cpconfig обычно
    # копирует это из \config\apppath при первом обращении, но подстраховка не мешает.
    "$CPCONFIG" -ini '\config\KeyDevices\PCSC\PNP PCSC\Default' -add string libpcsclite.so ${pkgs.pcsclite.lib}/lib/libpcsclite.so >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\KeyDevices\PCSC\PNP PCSC\Default\Name' -delparam >/dev/null 2>&1 || true

    for k in OSCAR OSCAR2 TRUST TRUSTS TRUSTD; do
      "$CPCONFIG" -ini "\\config\\KeyCarriers\\$k" -add string DLL librdrric.so >/dev/null 2>&1 || true
    done

    "$CPCONFIG" -hardware media -add oscar  -name 'Oscar'         >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar -add hex atr  0000000000000043525950544f5052      >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar -add hex mask 00000000000000ffffffffffffffff      >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar -add string folders 0B00                          >/dev/null 2>&1 || true

    "$CPCONFIG" -hardware media -add oscar2 -name 'Oscar CSP 2.0' >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add hex atr  000000000000004350435350010102     >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add hex mask 00000000000000ffffffffffffffff     >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add string folders 0B00                         >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add long size_1 60                              >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add long size_2 70                              >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add long size_4 60                              >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add long size_5 70                              >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -add long size_6 62                              >/dev/null 2>&1 || true

    "$CPCONFIG" -hardware media -add oscar2 -connect KChannel -name 'Channel K' >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -connect KChannel -add hex atr  000000000000004350435350010101 >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -connect KChannel -add hex mask 00000000000000ffffffffffffffff >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure oscar2 -connect KChannel -add string folders 0B00       >/dev/null 2>&1 || true
    for kv in "size_1 56" "size_2 36" "size_4 56" "size_5 36" "size_6 62"; do
      "$CPCONFIG" -hardware media -configure oscar2 -connect KChannel -add long ''${kv} >/dev/null 2>&1 || true
    done

    "$CPCONFIG" -hardware media -add TRUST  -name 'Foros (Magistra)' >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUST  -add hex atr  3b9e00008031c0654d4700000072f7418107 >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUST  -add hex mask ffff0000ffffffffffff300000ffffffffff >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUST  -add string folders 'A\B\C\D\E\F\G\H'              >/dev/null 2>&1 || true

    "$CPCONFIG" -hardware media -add TRUSTS -name 'Foros SocCard' >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUSTS -add hex atr  3b9a00008031c0610072f7418107        >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUSTS -add hex mask ffff0000ffffffff30ffffffffff        >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUSTS -add string folders 'A\B\C\D'                     >/dev/null 2>&1 || true

    "$CPCONFIG" -hardware media -add TRUSTD -name 'Foros Debug' >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUSTD -add hex atr  3b9800008031c072f7418107            >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUSTD -add hex mask ffff0000ffffffffffffffff            >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure TRUSTD -add string folders 'A\B\C\D\E\F\G\H'             >/dev/null 2>&1 || true

    # --- cprocsp-rdr-rutoken-64 postinst: Rutoken media families
    "$CPCONFIG" -ini '\config\apppath' -add string librdrrutoken.so "$LIBDIR/librdrrutoken.so" >/dev/null 2>&1 || true

    register_rutoken_media() {
      # $1=key $2=name $3=atr_hex $4=mask_hex
      "$CPCONFIG" -ini "\\config\\KeyCarriers\\$1" -add string DLL librdrrutoken.so >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -add "$1" -name "$2" >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -configure "$1" -add hex atr  "$3" >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -configure "$1" -add hex mask "$4" >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -configure "$1" -add string folders \
        '0A00\0B00\0C00\0D00\0E00\0F00\1000\1100\1200\1300\1400\1500\1600\1700\1800' >/dev/null 2>&1 || true
      for kv in "size_1 60" "size_2 70" "size_3 8" "size_4 60" "size_5 70" "size_6 300" "size_7 8"; do
        "$CPCONFIG" -hardware media -configure "$1" -add long ''${kv} >/dev/null 2>&1 || true
      done
    }

    register_rutoken_media RutokenECP     'Rutoken ECP'        3b8b015275746f6b656e20445320c1     ffffffffffffffffffffffffffffff
    register_rutoken_media RutokenFkcOld  'CryptoPro Rutoken'  3b8b015275746f6b656e20454350a0     ffffffffffffffffffffffffffffff
    register_rutoken_media RutokenECPSC   'Rutoken ECP SC'     3b9c96005275746f6b656e4543507363   ffffffffffffffffffffffffffffffff
    register_rutoken_media RutokenLiteSC2 'Rutoken Lite SC'    3b9e96005275746f6b656e4c697465534332 ffffffffffffffffffffffffffffffffffff
    register_rutoken_media RutokenLite    'Rutoken lite'       3b8b015275746f6b656e6c697465c2     ffffffffffffffffffffffffffffff
    register_rutoken_media Rutoken        'Rutoken S'          3b6f00ff00567275546f6b6e73302000009000 ffffffffffffffffffffffffffffffffffffff

    "$CPCONFIG" -ini '\config\KeyCarriers\RutokenPinpad' -add string DLL librdrrutoken.so >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -add RutokenPinpad -name 'Rutoken PinPad' >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure RutokenPinpad -add hex atr  3B8B01527450494E5061642020329C >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure RutokenPinpad -add hex mask ffffffffffffffffffffffffffffff >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure RutokenPinpad -add string folders \
      '0A00\0B00\0C00\0D00\0E00\0F00\1000\1100\1200\1300\1400\1500\1600\1700\1800' >/dev/null 2>&1 || true

    register_rutoken_2151() {
      # $1=key $2=name $3=atr $4=mask
      "$CPCONFIG" -ini "\\config\\KeyCarriers\\$1" -add string DLL librdrrutoken.so >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -add "$1" -name "$2" >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -configure "$1" -add hex atr  "$3" >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -configure "$1" -add hex mask "$4" >/dev/null 2>&1 || true
      "$CPCONFIG" -hardware media -configure "$1" -add string folders \
        '0A00\0B00\0C00\0D00\0E00\0F00\1000\1100\1200\1300\1400\1500\1600\1700\1800' >/dev/null 2>&1 || true
      for kv in "size_1 60" "size_2 70" "size_3 3072" "size_4 60" "size_5 70" "size_6 300" "size_7 8"; do
        "$CPCONFIG" -hardware media -configure "$1" -add long ''${kv} >/dev/null 2>&1 || true
      done
    }
    register_rutoken_2151 RutokenECPM   'Rutoken ECP 2151'    3B18967275746F6B656E6D       ffffffffffffffffffffff
    register_rutoken_2151 RutokenECPMSC 'Rutoken ECP 2151 SC' 3B1A967275746F6B656E6D7363   ffffffffffffffffffffffffff

    "$CPCONFIG" -ini '\config\KeyCarriers\RutokenNFC' -add string DLL librdrrutoken.so >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -add RutokenNFC -name 'Rutoken NFC' >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure RutokenNFC -connect Default -add hex atr  3B9C968011405275746F6B656E4543507363C0 >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure RutokenNFC -connect Default -add hex mask fffffefffffffffffffffffffffffffffffffe >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware media -configure RutokenNFC -connect Default -add string folders \
      '0A00\0B00\0C00\0D00\0E00\0F00\1000\1100\1200\1300\1400\1500\1600\1700\1800' >/dev/null 2>&1 || true
    for kv in "size_1 60" "size_2 70" "size_3 3072" "size_4 60" "size_5 70" "size_6 300" "size_7 8"; do
      "$CPCONFIG" -hardware media -configure RutokenNFC -connect Default -add long ''${kv} >/dev/null 2>&1 || true
    done

    # --- cprocsp-rdr-gui-gtk-64 postinst: GUI random + libfgcpui apppath
    "$CPCONFIG" -ini '\config\apppath' -add string librdrrndmbio_gui_fgtk.so "$LIBDIR/librdrrndmbio_gui_fgtk.so" >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string libxcpui.so   "$LIBDIR/libfgcpui.so"  >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string xcpui_app     "$SBINDIR/xcpui_app"    >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\Random\Bio_gui' -add string DLL librdrrndmbio_gui_fgtk.so >/dev/null 2>&1 || true
    "$CPCONFIG" -hardware rndm -add bio_gui -name 'rndm GUI GTK' -level 4 >/dev/null 2>&1 || true

    # 4a. cprocsp-pki-cades-64 postinst — apppath libs + policy OIDs + лицензии.
    #     После слияния cades в cryptoproCsp libs доступны через $LIBDIR.
    "$CPCONFIG" -ini '\config\apppath' -add string libcades.so        "$LIBDIR/libcades.so"        >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string libcppcades.so     "$LIBDIR/libcppcades.so"     >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string libpkivalidator.so "$LIBDIR/libpkivalidator.so" >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\apppath' -add string librevprov.so      "$LIBDIR/librevprov.so"      >/dev/null 2>&1 || true

    "$CPCONFIG" -ini '\config\policy\OIDs' -add string '{A4CC781E-04E9-425C-AAFD-1D74DA8DFAF6}' 'libpkivalidator.so CertDllVerifyOCSPSigningCertificateChainPolicy' >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\policy\OIDs' -add string '{AF74EE92-A059-492F-9B4B-EAD239B22A1B}' 'libpkivalidator.so CertDllVerifyTimestampSigningCertificateChainPolicy' >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\policy\OIDs' -add string '{B52FF66F-13A5-402C-B958-A3A6B5300FB6}' 'libpkivalidator.so CertDllVerifySignatureCertificateChainPolicy' >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\config\policy\OIDs' -add string '5' 'libpkivalidator.so BasicConstraintsImpl' >/dev/null 2>&1 || true
    "$CPCONFIG" -ini '\cryptography\OID\EncodingType 1\CertDllVerifyRevocation\DEFAULT' -add string 'DLL' 'librevprov.so' >/dev/null 2>&1 || true

    # OCSP/TSP лицензии — встроены в постинст cprocsp-pki-cades-64.
    "$SBINDIR/../bin/amd64/ocsputil" license -s 0A202-U0030-00ECW-RRLMF-UU2WK >/dev/null 2>&1 || true
    "$SBINDIR/../bin/amd64/tsputil"  license -s TA200-G0030-00ECW-RRLNE-BTDVV  >/dev/null 2>&1 || true

    # 4b. cprocsp-pki-plugin-64 postinst — apppath libnpcades.so.
    "$CPCONFIG" -ini '\config\apppath' -add string libnpcades.so "$LIBDIR/libnpcades.so" >/dev/null 2>&1 || true

    # 5. Per-user CA install. Cades plugin запускается из user-context,
    #    поэтому проверка цепочки идёт через user-stores (uRoot/uCA), НЕ
    #    machine-stores (mRoot/mCA). Без правильно установленных CA в
    #    user-stores Точка/Диадок отвечают "Status: Не действителен".
    #    Идемпотентно: certmgr -inst при дубликате печатает warning и
    #    возвращает нон-зеро, мы это глотаем через '|| true'.
    mkdir -p /var/opt/cprocsp/users/decard
    # chown -R: предыдущие попытки могли оставить root-owned файлы (когда
    # certmgr запускали через sudo), runuser certmgr не сможет их перезаписать.
    chown -R decard:users /var/opt/cprocsp/users/decard
    chmod 0700 /var/opt/cprocsp/users/decard
    # Если в users/global.ini нет файла — копируем skeleton (cp -rn выше
    # его поднимет, но на пустом /var активация может опередить cp на
    # самом первом rebuild — подстраховка):
    if [ ! -f /var/opt/cprocsp/users/global.ini ] && \
       [ -f ${cryptoproCsp}/var/opt/cprocsp/users/global.ini ]; then
      cp ${cryptoproCsp}/var/opt/cprocsp/users/global.ini /var/opt/cprocsp/users/global.ini
      chmod 0644 /var/opt/cprocsp/users/global.ini
    fi
    # Mass-install всех CA из .deb tmpcerts. Это и есть постинст
    # lsb-cprocsp-ca-certs. Ставится в обе пары stores: u (под decard,
    # для browser-плагинов) и m (под root, для CLI/system контекстов).
    # Без полного набора Cades не строит цепочку для свежих ФНС-сертов
    # (например, ИП 2024 года выдан УЦ ФНС России 2024_01).
    CERTMGR=${cryptoproCsp}/opt/cprocsp/bin/amd64/certmgr
    TMP_ROOT=${cryptoproCsp}/var/opt/cprocsp/tmpcerts/root
    TMP_CA=${cryptoproCsp}/var/opt/cprocsp/tmpcerts/ca

    # mRoot/mCA — system-wide (как обычный postinst через root)
    for c in "$TMP_ROOT"/*.cer; do
      [ -f "$c" ] || continue
      echo 'o' | "$CERTMGR" -inst -file "$c" -store mRoot >/dev/null 2>&1 || true
    done
    for c in "$TMP_CA"/*.cer; do
      [ -f "$c" ] || continue
      "$CERTMGR" -inst -file "$c" -store mCA >/dev/null 2>&1 || true
    done

    # uRoot/uCA — per-user (для browser-плагинов под decard)
    ${pkgs.util-linux}/bin/runuser -u decard -- ${pkgs.bash}/bin/bash -c "
      for c in $TMP_ROOT/*.cer; do
        [ -f \"\$c\" ] || continue
        echo 'o' | $CERTMGR -inst -file \"\$c\" -store uRoot >/dev/null 2>&1 || true
      done
      for c in $TMP_CA/*.cer; do
        [ -f \"\$c\" ] || continue
        $CERTMGR -inst -file \"\$c\" -store uCA >/dev/null 2>&1 || true
      done
      # Дополнительно — отдельно скачанные актуальные корневой и промежуточные
      # (.deb tmpcerts отстаёт от выпускаемых ФНС/Минцифрой обновлений).
      # ФНС-2024_01 критичен для сертификатов ИП 2025 года выпуска.
      echo 'o' | $CERTMGR -inst -file ${mintsifryCA2022} -store uRoot >/dev/null 2>&1 || true
      $CERTMGR -inst -file ${fnsCA2023} -store uCA >/dev/null 2>&1 || true
      $CERTMGR -inst -file ${fnsCA2024} -store uCA >/dev/null 2>&1 || true
    " || true
    # И в machine stores тоже — не помешает.
    "$CERTMGR" -inst -file ${fnsCA2024} -store mCA >/dev/null 2>&1 || true
  '';

  environment.systemPackages = [
    cryptoproCsp
    konturPlugin
    diagPlugin
    pkgs.pcsc-tools
    pkgs.opensc
  ];

  # Native Messaging hosts — кладём в три места:
  #   /etc/chromium/native-messaging-hosts/             — Chromium и
  #     Chromium-derivative'ы которые не оверрайдят manifest path.
  #   /etc/opt/chrome/native-messaging-hosts/           — Google Chrome.
  #   /etc/opt/yandex/browser/native-messaging-hosts/   — Yandex.Browser.
  # Yandex может работать через chromium-fallback, но первичный путь —
  # /etc/opt/yandex/browser/. Дубликат гарантирует обнаружение.
  environment.etc = {
    "chromium/native-messaging-hosts/ru.cryptopro.nmcades.json".text       = nmcadesNmHost;
    "opt/chrome/native-messaging-hosts/ru.cryptopro.nmcades.json".text     = nmcadesNmHost;
    "opt/yandex/browser/native-messaging-hosts/ru.cryptopro.nmcades.json".text = nmcadesNmHost;

    "chromium/native-messaging-hosts/kd.nc.json".text       = diagNmHost;
    "opt/chrome/native-messaging-hosts/kd.nc.json".text     = diagNmHost;
    "opt/yandex/browser/native-messaging-hosts/kd.nc.json".text = diagNmHost;

    "chromium/native-messaging-hosts/kontur.plugin.json".text       = konturNmHost;
    "opt/chrome/native-messaging-hosts/kontur.plugin.json".text     = konturNmHost;
    "opt/yandex/browser/native-messaging-hosts/kontur.plugin.json".text = konturNmHost;
  };
}
