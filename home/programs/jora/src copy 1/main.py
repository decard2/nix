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
    while True:
        text = stream_recognizer.recognize_stream(duration=5)
        if text:
            print(f"📝 {text}")
            if "стоп" in text.lower():
                print("✅ Завершаю диктовку!")
                break

def main():
    global DICTATION_MODE

    # Проверяем окружение
    check_env()

    # Устанавливаем обработчик Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    # Инициализируем компоненты
    detector = VoiceDetector(sensitivity=VOICE_SENSITIVITY)
    recognizer = SpeechRecognizer()
    command_processor = CommandProcessor()

    print("🎧 Погнали, братан! Слушаю...")

    while True:
        if detector.is_speech():
            print("🗣️ О, слышу речь!")
            text = recognizer.record_until_silence(detector)
            if text:
                print(f"👉 Ты сказал: {text}")

                # Обработка команд
                if command_processor.process(text):
                    start_dictation()

if __name__ == "__main__":
    main()
