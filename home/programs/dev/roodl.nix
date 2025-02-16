{ pkgs, lib, ... }:
let
  roodl = pkgs.stdenv.mkDerivation rec {
    pname = "roodl";
    version = "1.2.0";

    src = pkgs.fetchzip {
      url = "https://github.com/rolderdev/roodl1/releases/download/v${version}/Roodl-v${version}-Linux.zip";
      sha256 = "sha256-sRgO2mxMAfbtGXfQnqhbI+A9Rb9qCxBq6PNGsZHR0Ik=";
      stripRoot = false;
    };

    nativeBuildInputs = with pkgs; [
      makeWrapper
      appimage-run
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      fuse
      glib
      nss
      nspr
      dbus
      atk
      cups
      libdrm
      gtk3
      pango
      cairo
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      mesa
      expat
      libxkbcommon
      alsa-lib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/applications $out/opt/roodl

      cp -r linux-unpacked/* $out/opt/roodl/

      # Делаем бинарник исполняемым
      chmod +x $out/opt/roodl/roodl-editor

      # Создаем обертку
      makeWrapper $out/opt/roodl/roodl-editor $out/bin/roodl \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

      # Создаем .desktop файл
      cat > $out/share/applications/roodl.desktop << EOF
      [Desktop Entry]
      Name=Roodl
      Exec=$out/bin/roodl
      Type=Application
      Categories=Development;
      EOF

      runHook postInstall
    '';

    meta = with lib; {
      description = "Roodl Editor";
      homepage = "https://github.com/rolderdev/roodl1";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "roodl";
    };
  };
in
{
  home.packages = [ roodl ];
}
