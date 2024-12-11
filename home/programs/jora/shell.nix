{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    alsa-lib.dev
    alsa-utils
    openssl.dev
    cmake
  ];

  shellHook = ''
      export PKG_CONFIG_PATH="${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
    echo "🎤 Жора готов к записи!"
  '';
}
