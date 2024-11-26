{pkgs, ...}: {
  home.packages = with pkgs; [
    # Яндекс для обычного серфинга
    yandex-browser

    # Чистый Chromium для разработки
    chromium
  ];

  # Настройки для Chromium (минималистичные, для разработки)
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--force-dark-mode" # Тёмная тема
      "--enable-features=VaapiVideoDecoder" # Поддержка VAAPI для видео
    ];
  };

  # Добавляем Bitwarden в Яндекс
  xdg.configFile."yandex-browser/Default/Extensions/bitwarden.json".text = ''
    {
      "environment": "self-hosted",
      "server": "https://vault.decard.rolder.app",
      "pinLock": true,
      "pinLockOption": 0
    }
  '';
}
