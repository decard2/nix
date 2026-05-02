{ pkgs, ... }:
let
  vkplay-gamecenter = pkgs.stdenv.mkDerivation rec {
    pname = "vkplay-gamecenter";
    version = "1.16";

    src = pkgs.fetchurl {
      url = "https://static.gc.vkplay.ru/gclinux/deb_repo/GameCenterShowcase_amd64.deb";
      hash = "sha256-gFam5EaWW4LPeJjhaxJClGXwf+X2uTc/7jJSPSqRnOs=";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      makeWrapper
      wrapGAppsHook3
    ];

    buildInputs = with pkgs; [
      alsa-lib
      atk
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      gdk-pixbuf
      glib
      gtk3
      libgbm
      libxkbcommon
      nss
      pango
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxfixes
      libxrandr
    ];

    dontWrapGApps = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r usr/lib   $out/
      cp -r usr/share $out/

      substituteInPlace $out/share/applications/GameCenterShowcase.desktop \
        --replace-fail "/usr/lib/GameCenterShowcase/GameCenterShowcase" \
                       "$out/bin/GameCenterShowcase"

      runHook postInstall
    '';

    postFixup = ''
      makeWrapper $out/lib/GameCenterShowcase/GameCenterShowcase \
        $out/bin/GameCenterShowcase \
        "''${gappsWrapperArgs[@]}"
    '';

    meta = with pkgs.lib; {
      description = "VK Play GameCenter — лаунчер игр платформы VK Play";
      homepage = "https://vkplay.ru/play/";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "GameCenterShowcase";
    };
  };
in
{
  home.packages = [ vkplay-gamecenter ];
}
