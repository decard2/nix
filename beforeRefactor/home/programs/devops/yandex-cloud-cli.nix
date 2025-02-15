{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "yandex-cloud-cli";
  version = "0.139.0";

  src = fetchurl {
    url = "https://storage.yandexcloud.net/yandexcloud-yc/release/${version}/linux/amd64/yc";
    hash = "sha256-dwpb9Fn7sS0Ei2jn7kDJfUhTN5xHdLruAedu8hejA2w=";
  };

  nativeBuildInputs = [
    autoPatchelfHook # Для автоматической работы с зависимостями
  ];

  # Нам не нужна фаза распаковки, т.к. скачиваем готовый бинарник
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    # Создаём нужные директории
    mkdir -p $out/bin

    # Копируем и делаем исполняемым бинарник
    cp $src $out/bin/yc
    chmod +x $out/bin/yc

    runHook postInstall
  '';

  meta = with lib; {
    description = "Yandex Cloud CLI";
    homepage = "https://cloud.yandex.ru/docs/cli/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
