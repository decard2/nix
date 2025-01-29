{
  # Автоматическая активация flox
  __flox_auto_activate = {
    body = ''
      # Проверяем, не находимся ли мы уже в процессе активации
      if test -z "$FLOX_ACTIVATING"
        set -x FLOX_ACTIVATING 1

        # Проверяем наличие .flox в текущей директории
        if test -e .flox
          set -l active_env (flox envs --active --json | string join ' ')
          if test -z "$active_env"
            echo \n🚀 Активация flox окружения...\n
            flox activate -- fish
          end
        end

        set -e FLOX_ACTIVATING
      end
    '';
    onVariable = "PWD";
  };

  deployRoodl = {
    body = builtins.readFile ../../../bin/deployRoodl.fish;
  };

  check_and_start_hyprland = {
    body = ''
      if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY"
        if command -v Hyprland >/dev/null
          exec Hyprland
        else
          echo "❌ Hyprland не найден"
        end
      end
    '';
  };

  cleanNix = {
    body = ''
      function cleanup --on-signal SIGINT
          echo -e "\n👋 Ладно, понял, выходим без уборки!"
          exit 1
      end

      function confirm
          while true
              read -l -P "$argv[1] (y/n) " confirm

              # Проверяем статус выхода для Ctrl+C
              if test $status -eq 1
                  exit 1
              end

              switch $confirm
                  case Y y
                      return 0
                  case N n
                      return 1
              end
          end
      end

      echo "🧹 Начинаем уборку системы..."

      if confirm "Удалить старые поколения системы?"
          echo "💨 Удаляем старые поколения..."
          sudo nix-collect-garbage -d
          # Проверяем успешность выполнения
          if test $status -ne 0
              echo "❌ Ошибка при удалении поколений!"
              exit 1
          end
          echo "✅ Старые поколения удалены"
      end

      if confirm "Удалить старые поколения пользователя?"
          echo "💨 Удаляем старые поколения..."
          nix-collect-garbage -d
          # Проверяем успешность выполнения
          if test $status -ne 0
              echo "❌ Ошибка при удалении поколений!"
              exit 1
          end
          echo "✅ Старые поколения удалены"
      end


      if confirm "Удалить неиспользуемые пакеты из nix store?"
          echo "🗑️ Очищаем nix store..."
          nix-store --gc
          if test $status -ne 0
              echo "❌ Ошибка при очистке nix store!"
              exit 1
          end
          echo "✅ Nix store очищен"
      end

      if confirm "Оптимизировать nix store?"
          echo "🔄 Оптимизируем nix store..."
          sudo nix-store --optimize
          if test $status -ne 0
              echo "❌ Ошибка при оптимизации nix store!"
              exit 1
          end
          echo "✅ Nix store оптимизирован"
      end

      echo "⚡ Пересобираем систему..."
      sudo nixos-rebuild switch --flake ~/nix#emerald
      if test $status -ne 0
          echo "❌ Ошибка при пересборке системы!"
          exit 1
      end
      echo "✅ Система успешно пересобрана"

      if confirm "Перезагрузить систему сейчас?"
          echo "🔄 Перезагружаемся..."
          sudo reboot
      else
          echo "👍 Окей, перезагрузишь сам когда нужно"
      end

      echo "🎉 Уборка завершена! Система сияет чистотой!"
    '';
  };
}
