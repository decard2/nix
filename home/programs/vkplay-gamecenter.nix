{ pkgs, ... }:
let
  # Распакованный .deb. Без autoPatchelfHook, потому что лаунчер
  # при первом запуске копирует себя в ~/.local/share/GameCenterShowcase/
  # и оттуда запускает обновлённую версию — пропатченные RUNPATH у этой
  # копии теряются, проще всё держать в FHS-окружении.
  gameCenterFiles = pkgs.stdenvNoCC.mkDerivation {
    pname = "vkplay-gamecenter-files";
    version = "1.16";

    src = pkgs.fetchurl {
      url = "https://static.gc.vkplay.ru/gclinux/deb_repo/GameCenterShowcase_amd64.deb";
      hash = "sha256-gFam5EaWW4LPeJjhaxJClGXwf+X2uTc/7jJSPSqRnOs=";
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp -r usr/lib   $out/
      cp -r usr/share $out/
      ln -s $out/lib/GameCenterShowcase/GameCenterShowcase $out/bin/GameCenterShowcase
      runHook postInstall
    '';

    dontPatchELF = true;
    dontStrip = true;
  };
in
{
  home.packages = [
    (pkgs.buildFHSEnv {
      name = "GameCenterShowcase";

      targetPkgs =
        p: with p; [
          gameCenterFiles

          # Базовая графика/GTK
          atk
          at-spi2-atk
          at-spi2-core
          cairo
          fontconfig
          freetype
          gdk-pixbuf
          glib
          gtk3
          pango

          # Chromium/CEF runtime
          dbus
          expat
          libdrm
          libgbm
          libglvnd # libGL/libEGL
          libxkbcommon
          libxkbfile
          mesa
          nspr
          nss
          systemd # libudev
          vulkan-loader

          # X11
          libx11
          libxcb
          libxcomposite
          libxcursor
          libxdamage
          libxext
          libxfixes
          libxi
          libxrandr
          libxrender
          libxscrnsaver
          libxshmfence
          libxtst

          # Сеть/крипта
          curl
          openssl
          zlib

          # Аудио/печать
          alsa-lib
          cups
          libpulseaudio
        ];

      runScript = "GameCenterShowcase";

      extraInstallCommands = ''
        mkdir -p $out/share
        cp -r ${gameCenterFiles}/share/applications $out/share/
        cp -r ${gameCenterFiles}/share/icons        $out/share/
        substituteInPlace $out/share/applications/GameCenterShowcase.desktop \
          --replace-fail "/usr/lib/GameCenterShowcase/GameCenterShowcase" \
                         "$out/bin/GameCenterShowcase"
      '';

      meta = with pkgs.lib; {
        description = "VK Play GameCenter — лаунчер игр платформы VK Play";
        homepage = "https://vkplay.ru/play/";
        license = licenses.unfree;
        platforms = [ "x86_64-linux" ];
        mainProgram = "GameCenterShowcase";
      };
    })
  ];
}
