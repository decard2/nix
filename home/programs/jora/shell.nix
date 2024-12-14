{pkgs ? import <nixpkgs> {}}: let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      pip
    ]);
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      pythonEnv
      portaudio
      alsa-lib
      opusTools
      stdenv.cc.cc.lib
      wtype
    ];

    shellHook = ''
      echo "🎤 Жора на связи!"
      echo "🚀 Погнали шуметь!"

      # API ключи Яндекса
      # Получаем ключи из заметок Bitwarden
      echo "🔐 Загружаю ключи из Bitwarden..."

      export YANDEX_FOLDER_ID="$(${pkgs.rbw}/bin/rbw get yandex-speech-keys --full | ${pkgs.gnugrep}/bin/grep 'folder_id:' | cut -d' ' -f2-)"
      export YANDEX_OAUTH_TOKEN="$(${pkgs.rbw}/bin/rbw get yandex-speech-keys --full | ${pkgs.gnugrep}/bin/grep 'oauth_token:' | cut -d' ' -f2-)"
      export YANDEX_API_KEY="$(${pkgs.rbw}/bin/rbw get yandex-speech-keys --full | ${pkgs.gnugrep}/bin/grep 'api_key:' | cut -d' ' -f2-)"

      if [ -z "$YANDEX_FOLDER_ID" ] || [ -z "$YANDEX_OAUTH_TOKEN" ] || [ -z "$YANDEX_API_KEY" ]; then
        echo "❌ Не удалось получить ключи из Bitwarden! Проверь, что rbw настроен и залогинен."
        exit 1
      fi

      if [ ! -d ".venv" ]; then
        ${pythonEnv}/bin/python -m venv .venv
        source .venv/bin/activate
        pip install -q torch torchaudio sounddevice pyaudio numpy grpcio-tools
        deactivate
      fi

      export PATH="$PWD/.venv/bin:$PATH"
      export PYTHONPATH="$PWD/.venv/lib/python3.*/site-packages:$PWD/cloudapi/output:$PYTHONPATH"

      # Путь к библиотекам C++
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.portaudio}/lib:$LD_LIBRARY_PATH"

      if [ ! -d "cloudapi" ]; then
        git clone https://github.com/yandex-cloud/cloudapi
        cd cloudapi
        mkdir -p output
        source ../.venv/bin/activate
        python -m grpc_tools.protoc -I . -I third_party/googleapis \
          --python_out=output \
          --grpc_python_out=output \
          google/api/http.proto \
          google/api/annotations.proto \
          yandex/cloud/api/operation.proto \
          google/rpc/status.proto \
          yandex/cloud/operation/operation.proto \
          yandex/cloud/validation.proto \
          yandex/cloud/ai/stt/v3/stt_service.proto \
          yandex/cloud/ai/stt/v3/stt.proto
        deactivate
        cd ..
      fi
    '';

    PORTAUDIO_PATH = "${pkgs.portaudio}";
  }
