{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation {
  pname = "rcli";
  version = "0.8.0";

  src = fetchurl {
    url = "https://dev.rolder.app/~downloads/projects/42/builds/10/artifacts/rcli";
    sha256 = lib.fakeSha256; # При первом запуске выдаст правильный хеш
  };

  dontUnpack = true; # Бинарник не надо распаковывать

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/rcli
    chmod +x $out/bin/rcli
  '';

  meta = with lib; {
    description = "Rolder CLI";
    homepage = "https://dev.rolder.app/rolder/rcli/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
