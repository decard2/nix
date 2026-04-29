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

    nativeBuildInputs = [ pkgs.dpkg ];

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
    dontPatchELF = true;       # we patch in Phase 2
    dontAutoPatchelf = true;
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

    nativeBuildInputs = [ pkgs.dpkg ];

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
    dontPatchELF = true;
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
    pkgs.pcsc-tools
    pkgs.opensc
  ];
}
