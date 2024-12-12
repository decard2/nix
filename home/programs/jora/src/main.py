import os
import signal
import sys
from detector import VoiceDetector
from recognizer import SpeechRecognizer
from stream_recognizer import StreamRecognizer
from commands import CommandProcessor

# Настройки
VOICE_SENSITIVITY = 0.7  # Чувствительность детектора речи (0.0 - 1.0)
DICTATION_MODE = False  # Флаг режима диктовки

def check_env():
    """Проверяем наличие необходимых переменных окружения"""
    required = ['YANDEX_FOLDER_ID', 'YANDEX_OAUTH_TOKEN', 'YANDEX_API_KEY']
    missing = [var for var in required if not os.getenv(var)]

    if missing:
        print("❌ Братан, нет важных переменных окружения:", ', '.join(missing))
        print("💡 Проверь shell.nix!")
        sys.exit(1)
    print("✅ Все переменные окружения на месте!")

def signal_handler(sig, frame):
    """Корректное завершение при Ctrl+C"""
    print("\n👋 Пока, братан! Завершаюсь...")
    sys.exit(0)

def start_dictation():
    """Режим диктовки"""
    stream_recognizer = StreamRecognizer()
    print("📝 Погнали диктовать! (Скажи 'Завершить запись' для завершения)")

    while True:
        text = stream_recognizer.recognize_stream()
        if text == "STOP_RECORDING":
            break
        elif text:  # печатаем только если есть что печатать
            print(f"📝 {text}")

def main():
    # Проверяем окружение
    check_env()

    # Устанавливаем обработчик Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    # Инициализируем компоненты
    detector = VoiceDetector(sensitivity=VOICE_SENSITIVITY)
    recognizer = SpeechRecognizer()
    stream_recognizer = StreamRecognizer()
    command_processor = CommandProcessor()
    command_processor.set_stream_recognizer(stream_recognizer)

    print("🎧 Погнали, братан! Слушаю...")

    while True:
        if detector.is_speech():
            if not command_processor.is_dictating:
                # Обычный режим - слушаем команды
                print("🗣️ О, слышу речь!")
                text = recognizer.record_until_silence(detector)
                if text:
                    print(f"👉 Ты сказал: {text}")
                    if command_processor.process(text):
                        # Если была распознана команда "записывай",
                        # сразу переходим к следующей итерации уже в режиме диктовки
                        continue
            else:
                # Режим диктовки
                stream_recognizer.recognize_stream()  # Теперь работает непрерывно
                if command_processor.is_dictating:  # Проверяем флаг после завершения
                    command_processor.is_dictating = False
                    print("\n✅ Диктовка завершена!")

if __name__ == "__main__":
    main()
