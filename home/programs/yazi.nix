{ ... }: {
  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_sensitive = false;
        sort_reverse = false;

        # Добавим крутые настройки
        layout = [
          1 # Колонок слева
          4 # Колонок в середине
          3 # Колонок справа
        ];

        preview = true;
        preview_tabwidth = 2;
      };

      preview = {
        max_width = 600;
        max_height = 900;

        # Добавим поддержку превью архивов
        archive_preview = true;

        # Улучшенные превью изображений
        image = {
          enabled = true;
          backend = "ueberzug"; # Лучше для Hyprland
          max_size = 10485760; # ~10MB макс размер
        };
      };
    };
  };
}
