import os
import argparse
import signal
import sys
from typing import Optional
import numpy as np # type: ignore

from src.recognition.detector import VoiceDetector
from src.audio.audio_recorder import AudioRecorder
from src.audio.debug_player import DebugPlayer
from src.utils.logger import info, debug, set_debug, error
from src.utils.config import config

# Глобальная переменная для хранения ссылки на помощника
jora = None

class Jora:
    """Основной класс голосового помощника"""

    def __init__(self, args: argparse.Namespace):
        """Инициализация помощника"""
        self.args = args
        self.should_stop = False

        # Детектор речи
        self.detector = VoiceDetector(
            sensitivity=args.sensitivity,
            min_silence_ms=args.min_silence,
            speech_pad_ms=args.speech_pad
        )

        # Recorder создается при начале записи
        self.recorder: Optional[AudioRecorder] = None

    def start_recording(self, initial_audio: Optional[np.ndarray] = None):
        """Начинает запись речи"""
        if not self.recorder:
            self.recorder = AudioRecorder()
            if not self.recorder.start_recording(initial_audio):
                error("Не удалось начать запись")
                self.recorder = None
            else:
                info("🎤 Начало речи")

    def stop_recording(self):
        """Останавливает запись речи"""
        if self.recorder:
            if audio_file := self.recorder.stop_recording():
                debug("Запись остановлена")
                info("🔇 Конец речи")

                # В режиме отладки воспроизводим
                if config.DEBUG:
                    DebugPlayer.play_file(audio_file)

                # TODO: Отправляем на распознавание

            self.recorder.cleanup()
            self.recorder = None

    def process_audio(self):
        """Обработка аудио потока"""
        # Получаем текущее состояние речи
        state = self.detector.process_audio()

        # Добавляем логирование состояния
        if state:
            debug(f"Получено состояние: {state['type']}")

            # Начало речи
            if state['type'] == 'start':
                debug("🎤 Начинаем запись")
                self.start_recording(state.get('audio'))

            # Конец речи
            elif state['type'] == 'end':
                debug("🔇 Завершаем запись")
                self.stop_recording()

        # Записываем если есть активная запись
        if self.recorder:
            self.recorder.process()

    def run(self):
        """Основной цикл работы"""
        info("Погнали, братан! Слушаю...")

        while not self.should_stop:
            self.process_audio()

    def stop(self):
        """Остановка помощника"""
        self.should_stop = True
        if self.recorder:
            self.stop_recording()  # Убрал параметр current_sample
        self.detector.cleanup()

    def __del__(self):
        """Очистка ресурсов при удалении"""
        self.stop()

def parse_args() -> argparse.Namespace:
    """Парсинг аргументов командной строки"""
    parser = argparse.ArgumentParser(description='Жора - голосовой помощник')
    parser.add_argument(
        '--debug', '-d',
        action='store_true',
        help='Включить режим отладки'
    )
    parser.add_argument(
        '--sensitivity', '-s',
        type=float,
        default=0.5,
        help='Чувствительность детектора речи (0.0 - 1.0)'
    )
    parser.add_argument(
        '--min-silence', '-m',
        type=int,
        default=100,
        help='Минимальная длительность тишины (мс)'
    )
    parser.add_argument(
        '--speech-pad', '-p',
        type=int,
        default=30,
        help='Padding речи (мс)'
    )
    return parser.parse_args()

def signal_handler(sig, frame):
    """Корректное завершение при Ctrl+C"""
    global jora
    if jora:
        jora.stop()
    info("\nПока, братан! Завершаюсь...")
    sys.exit(0)

def check_environment() -> bool:
    """Проверка окружения"""
    required_envs = [
        'YANDEX_FOLDER_ID',
        'YANDEX_OAUTH_TOKEN',
        'YANDEX_API_KEY'
    ]

    missing = [env for env in required_envs if not os.getenv(env)]

    if missing:
        error(f"Отсутствуют переменные окружения: {', '.join(missing)}")
        error("Проверь shell.nix!")
        return False

    debug("✅ Все переменные окружения на месте")
    return True

def main():
    # Парсим аргументы
    args = parse_args()

    # Включаем режим отладки если нужно
    if args.debug:
        config.enable_debug()
        set_debug(True)
        debug("Режим отладки включен!")

    # Проверяем окружение
    if not check_environment():
        sys.exit(1)

    # Создаем помощника
    global jora
    jora = Jora(args)

    # Устанавливаем обработчик Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    try:
        # Запускаем
        jora.run()
    except Exception as e:
        error(f"Критическая ошибка: {e}")
        sys.exit(1)
    finally:
        if jora:
            jora.stop()

if __name__ == "__main__":
    main()
