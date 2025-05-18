# {
#   lib,
#   stdenv,
#   fetchurl,
#   autoPatchelfHook,
# }:
# stdenv.mkDerivation rec {
#   pname = "yandex-cloud-cli";
#   version = "0.152.0";

#   src = fetchurl {
#     url = "https://storage.yandexcloud.net/yandexcloud-yc/release/${version}/linux/amd64/yc";
#     hash = "sha256-uXIhrkvtVyjafyqowjRrSXd7JsU/0vBPc8Qghc9f7bo=";
#   };

#   nativeBuildInputs = [
#     autoPatchelfHook # Для автоматической работы с зависимостями
#   ];

#   # Нам не нужна фаза распаковки, т.к. скачиваем готовый бинарник
#   dontUnpack = true;

#   installPhase = ''
#     runHook preInstall

#     # Создаём нужные директории
#     mkdir -p $out/bin

#     # Копируем и делаем исполняемым бинарник
#     cp $src $out/bin/yc
#     chmod +x $out/bin/yc

#     runHook postInstall
#   '';

#   meta = with lib; {
#     description = "Yandex Cloud CLI";
#     homepage = "https://cloud.yandex.ru/docs/cli/";
#     license = licenses.mit;
#     platforms = platforms.linux;
#   };
# }
