{ pkgs, lib, ... }:
let
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
      stdenv.cc.cc.lib
    ];

    unpackPhase = ''
      runHook preUnpack
      tar xzf $src
      cd linux-amd64_deb
      runHook postUnpack
    '';

    buildPhase = ''
      runHook preBuild
      mkdir -p extracted
      for d in \
        lsb-cprocsp-base_*.deb \
        lsb-cprocsp-rdr-64_*.deb \
        lsb-cprocsp-kc1-64_*.deb \
        lsb-cprocsp-capilite-64_*.deb \
        cprocsp-rdr-rutoken-64_*.deb \
        cprocsp-rdr-pcsc-64_*.deb \
        cprocsp-rdr-gui-gtk-64_*.deb \
        lsb-cprocsp-pkcs11-64_*.deb \
        lsb-cprocsp-ca-certs_*.deb \
      ; do
        dpkg-deb -x $d extracted
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

  cprocspCades = pkgs.stdenv.mkDerivation {
    pname = "cprocsp-cades";
    version = "2.0.15600-1";

    src = pkgs.requireFile {
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

    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      cryptoproCsp
      gtk3
      glib
      cairo
      openssl
      stdenv.cc.cc.lib
    ];

    # nmcades dlopen()-ит libcppki.so.4 и т.д. из cryptoproCsp в рантайме.
    # runtimeDependencies — добавляет ${cryptoproCsp}/lib в RPATH (но libs там нет!),
    # appendRunpaths — добавляет нужный путь opt/cprocsp/lib/amd64 в RPATH каждого ELF.
    appendRunpaths = [ "${cryptoproCsp}/opt/cprocsp/lib/amd64" ];

    # autoPatchelfHook ищет libs только в стандартных lib/ путях buildInputs.
    # CryptoPro кладёт shared-libs в нестандартный opt/cprocsp/lib/amd64 —
    # надо явно добавить этот путь в search-path для autoPatchelf.
    preFixup = ''
      addAutoPatchelfSearchPath ${cryptoproCsp}/opt/cprocsp/lib/amd64
    '';

    unpackPhase = ''
      runHook preUnpack
      tar xzf "$src"
      cd cades-linux-amd64
      runHook postUnpack
    '';

    buildPhase = ''
      runHook preBuild
      mkdir -p extracted
      for d in cprocsp-pki-cades-64_*.deb cprocsp-pki-plugin-64_*.deb; do
        dpkg-deb -x $d extracted
      done
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt $out/
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

    nativeBuildInputs = [ pkgs.dpkg ];

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
    dontPatchELF = true;       # we patch in Phase 2
    dontAutoPatchelf = true;
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

    nativeBuildInputs = [ pkgs.dpkg ];

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
    dontPatchELF = true;       # we patch in Phase 2
    dontAutoPatchelf = true;
  };
in {
  # Aktiv Co. — Rutoken family. MODE=0666 нужен потому что ранее требовался
  # mapped-root в distrobox; на нативном хосте `0664` + `uaccess` тоже бы
  # хватило, но 0666 универсально и не несёт риска (токен физически в твоей
  # машине). Оставляем как было.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0a89", MODE="0666"
  '';

  environment.systemPackages = [
    cryptoproCsp
    cprocspCades
    konturPlugin
    diagPlugin
    pkgs.pcsc-tools
    pkgs.opensc
  ];
}
