{pkgs, ...}: let
  vosk = pkgs.python3Packages.buildPythonPackage rec {
    pname = "vosk";
    version = "0.3.45";

    format = "wheel";

    src = pkgs.fetchPypi {
      inherit pname version;
      format = "wheel";
      python = "py3";
      platform = "manylinux_2_12_x86_64.manylinux2010_x86_64";
      hash = "sha256-JeAlCTxDmdcnj1Q1aO2MxUYKw6S/SMI2c6zh4l0mYZ8=";
    };

    propagatedBuildInputs = with pkgs.python3Packages; [
      cffi
      requests
      tqdm
      srt
    ];

    doCheck = false;
  };

  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      pyaudio
      vosk
    ]);

  voice-assistant = pkgs.writeScriptBin "voice-assistant" ''
    #!${pkgs.nushell}/bin/nu

    let config_dir = ($env.HOME + "/.config/voice-assistant")
    if not ($config_dir | path exists) {
        echo "📁 Создаю директорию конфига..."
        mkdir $config_dir
    }

    if not ($config_dir + "/model-ru" | path exists) {
        echo "📥 Скачиваю модель русского языка..."
        cd $config_dir
        ${pkgs.curl}/bin/curl -L https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip -o model.zip
        ${pkgs.unzip}/bin/unzip model.zip
        mv vosk-model-small-ru-0.22 model-ru
        rm model.zip
    }

    cd $config_dir
    echo "🎤 Запускаю голосового ассистента..."

    with-env { PYTHONPATH: $config_dir } {
        ${pythonEnv}/bin/python3 main.py
    }
  '';
in {
  home.packages = with pkgs; [
    voice-assistant
    pythonEnv
    alsa-utils
    ffmpeg
    wtype
  ];

  xdg.configFile = {
    "voice-assistant/main.py".source = ./main.py;
    "voice-assistant/voice_listener.py".source = ./voice_listener.py;
    "voice-assistant/command_executor.py".source = ./command_executor.py;
    "voice-assistant/colors.py".source = ./colors.py;
    "voice-assistant/__init__.py".text = "";
  };
}
