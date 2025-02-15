{ pkgs, ... }: {
  home.packages = with pkgs; [ telegram-desktop hunspell hunspellDicts.ru_RU ];

  # Основные настройки
  xdg.configFile."telegram-desktop/config.json".text = ''
    {
      "telegram_desktop": {
        "native_decorations": false,
        "use_system_window_frame": true,
        "spellchecking": {
          "enabled": true,
          "languages": ["ru"]
        },
        "notifications": {
          "desktop_enabled": false,
          "native_notifications": false,
          "muted_chats_counter": false,
          "count_muted_unread": false,
          "include_muted": false
        },
        "chat": {
          "send_by_ctrl_enter": true
        },
        "chat_theme": "night",
        "window_theme": "night"
      }
    }
  '';
}
