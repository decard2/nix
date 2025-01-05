{ pkgs, lib, ... }:
let
  roodl = pkgs.stdenv.mkDerivation rec {
    pname = "roodl";
    version = "1.1.0";

    src = pkgs.fetchzip {
      url =
        "https://github.com/rolderdev/roodl1/releases/download/v${version}/Roodl-v${version}-Linux.zip";
      sha256 = "05xwjp0m7z3x50vf6i1v6q9dcyma8x5adwnr6bzqyajzysnvp4qr";
      stripRoot = false;
    };

    nativeBuildInputs = with pkgs; [ makeWrapper appimage-run ];

    buildInputs = with pkgs; [ stdenv.cc.cc.lib fuse ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/applications $out/opt/roodl

      cp "${src}/Roodl Editor-${version}.AppImage" $out/opt/roodl/roodl.AppImage
      chmod +x $out/opt/roodl/roodl.AppImage

      makeWrapper ${pkgs.appimage-run}/bin/appimage-run $out/bin/roodl \
        --add-flags "$out/opt/roodl/roodl.AppImage"

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
in { home.packages = [ roodl ]; }
