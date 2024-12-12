import os
import sys
import signal
import argparse
from wake_word import WakeWordDetector
from silero_detector import SileroVadDetector
from recognition import SpeechRecognizer

# Глобальная переменная для детектора
detector = None

def signal_handler(sig, frame):
    print("\n👋 Пока, братан! Завершаюсь...")
    # Очищаем ресурсы перед выходом
    global detector
    if detector:
        detector.cleanup()
    sys.exit(0)

def check_env_vars():
    required_vars = [
        'YANDEX_FOLDER_ID',
        'YANDEX_OAUTH_TOKEN',
        'YANDEX_API_KEY',
        'PORCUPINE_ACCESS_KEY'
    ]
    missing = [var for var in required_vars if not os.getenv(var)]
    if missing:
        print("❌ Братан, нет важных переменных окружения:", ', '.join(missing))
        print("💡 Проверь shell.nix!")
        sys.exit(1)
    print("✅ Все переменные окружения на месте!")

def main():
    global detector

    # Регистрируем обработчик сигнала
    signal.signal(signal.SIGINT, signal_handler)

    check_env_vars()

    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=['wake_word', 'silero'],
                       default='wake_word',
                       help='Режим активации: wake_word или silero')
    args = parser.parse_args()

    recognizer = SpeechRecognizer()

    if args.mode == 'wake_word':
        detector = WakeWordDetector()
        print("🎧 Слушаю wake word, братан!")
        while True:
            if detector.check_wake_word():
                print("🔥 О, слышу ключевое слово!")
                detector.pause()
                text = recognizer.recognize_stream()
                print(f"👉 Ты сказал: {text}")
                detector.resume()
    else:  # silero
        detector = SileroVadDetector()
        print("🎧 Слушаю через Silero VAD, братан!")
        while True:
            if detector.check_speech():
                print("🔥 О, слышу речь!")
                detector.pause()
                text = recognizer.recognize_stream()
                print(f"👉 Ты сказал: {text}")
                detector.resume()

if __name__ == "__main__":
    main()
