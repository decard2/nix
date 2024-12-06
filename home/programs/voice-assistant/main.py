import os
import sys
import json
import time
from voice_listener import start_recording, process_audio
from command_executor import execute_command
from colors import Colors

def print_help():
    print(f"""
{Colors.HEADER}🎤 Голосовой ассистент{Colors.END}

{Colors.BLUE}Основные команды:{Colors.END}
- "телеграм" или "телега" - открыть Telegram
- "терминал" или "консоль" - открыть терминал
- "редактор" или "кодер" - открыть редактор кода
- "браузер" - открыть браузер
- "процессы" или "нагрузка" - открыть системный монитор
- "закрыть" - закрыть активное окно

{Colors.BLUE}Навигация:{Colors.END}
- "номер" - переключение между рабочими столами
- Можно комбинировать: "редактор два"

{Colors.BLUE}Режим диктовки:{Colors.END}
- "запись" - включить режим диктовки
- "стоп" - выключить режим диктовки
    """)

def main():
    # Инициализация
    stream, audio, ffmpeg_process = start_recording()
    print_help()
    print(f"{Colors.GREEN}🎤 Голосовой ассистент запущен{Colors.END}")

    # Кэш для предыдущих команд
    last_command = None
    last_command_time = 0
    COMMAND_COOLDOWN = 0.5  # Минимальный интервал между командами

    # Флаг режима диктовки
    dictation_mode = False

    try:
        for result in process_audio():
            current_time = time.time()

            # Парсим результат
            try:
                text = json.loads(result)["text"].strip()
            except (json.JSONDecodeError, KeyError):
                continue

            # Пропускаем пустые команды
            if not text:
                continue

            # Проверяем выход из режима диктовки
            if dictation_mode and "стоп" in text.lower():
                print(f"{Colors.GREEN}✅ Выхожу из режима диктовки{Colors.END}")
                dictation_mode = False
                continue

            # Проверяем команду помощи
            if "помощь" in text.lower() and not dictation_mode:
                print_help()
                continue

            # Проверяем кулдаун и дубликаты (только для обычного режима)
            if not dictation_mode:
                if current_time - last_command_time < COMMAND_COOLDOWN:
                    continue
                if text == last_command:
                    continue

            # Выполняем команду или обрабатываем диктовку
            try:
                print(f"\n{Colors.BLUE}🎯 {'Текст' if dictation_mode else 'Команда'}: '{text}'{Colors.END}")

                # Выполняем команду или вводим текст
                result = execute_command(text, dictation_mode)

                # Проверяем переключение в режим диктовки
                if result == "DICTATION_MODE":
                    dictation_mode = True
                    print(f"{Colors.GREEN}✅ Включен режим диктовки. Скажите 'стоп' для выхода{Colors.END}")

                last_command = text
                last_command_time = current_time

            except Exception as e:
                print(f"{Colors.FAIL}❌ Ошибка выполнения: {e}{Colors.END}")

    except KeyboardInterrupt:
        print(f"\n{Colors.WARNING}👋 Выключаюсь...{Colors.END}")
    finally:
        print(f"{Colors.WARNING}🧹 Освобождаю ресурсы...{Colors.END}")
        stream.stop_stream()
        stream.close()
        audio.terminate()
        ffmpeg_process.terminate()

if __name__ == "__main__":
    main()
