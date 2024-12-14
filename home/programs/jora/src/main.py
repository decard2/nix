import os
import argparse
import signal
import sys
from typing import Optional
from src.recognition.recognizer import CommandRecognizer
import numpy as np # type: ignore
import time

from src.recognition.detector import VoiceDetector
from src.audio.audio_recorder import AudioRecorder
from src.audio.debug_player import DebugPlayer
from src.utils.logger import info, debug, set_debug, error, log_timing
from src.utils.config import config

# Глобальная переменная для хранения ссылки на помощника
jora = None

class Jora:
    """Основной класс голосового помощника"""

    def __init__(self, args: argparse.Namespace):
        """Инициализация помощника"""
        self.args = args
        self.should_stop = False
        self.detector = VoiceDetector()
        self.recorder: Optional[AudioRecorder] = None
        self.recognizer = CommandRecognizer()

    def start_recording(self, initial_audio: Optional[np.ndarray] = None):
        """Начинает запись речи"""
        if not self.recorder:
            self.recorder = AudioRecorder()
            if not self.recorder.start_recording(initial_audio):
                error("Не удалось начать запись")
                self.recorder = None

    def stop_recording(self):
        """Останавливает запись речи"""
        if self.recorder:
            if audio_file := self.recorder.stop_recording():
                try:
                    # Замеряем только распознавание
                    start_time = time.time() if config.DEBUG else None

                    # Распознаем команду
                    if text := self.recognizer.recognize_command(audio_file):
                        info(f"🗣️ Распознано: {text}")
                    else:
                        info("❌ Команда не распознана")

                    # Логируем время распознавания
                    if config.DEBUG and start_time:
                        elapsed = (time.time() - start_time) * 1000
                        debug(f"Время распознавания: {elapsed:.1f}ms")

                    # Отдельно воспроизводим в режиме дебага
                    if config.DEBUG:
                        DebugPlayer.play_file(audio_file)

                finally:
                    try:
                        os.unlink(audio_file)
                    except Exception as e:
                        error(f"Ошибка удаления файла: {e}")

                    self.recorder.cleanup()
                    self.recorder = None

    def process_audio(self):
        """Обработка аудио потока"""
        state = self.detector.process_audio()

        if state:
            if state['type'] == 'start':
                self.start_recording(state.get('audio'))
            elif state['type'] == 'end':
                self.stop_recording()

        if self.recorder:
            self.recorder.process()

    def run(self):
        """Основной цикл работы"""

        while not self.should_stop:
            self.process_audio()

    def stop(self):
        """Остановка помощника"""
        self.should_stop = True
        if self.recorder:
            self.stop_recording()
        self.detector.cleanup()

    def __del__(self):
        """Очистка ресурсов при удалении"""
        self.stop()

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Жора - голосовой помощник')
    parser.add_argument('--debug', '-d', action='store_true', help='Режим отладки')
    parser.add_argument('--sensitivity', '-s', type=float, default=config.vad.SENSITIVITY,
                      help='Чувствительность детектора речи (0.0 - 1.0)')
    parser.add_argument('--min-silence', '-m', type=int, default=config.vad.MIN_SILENCE_MS,
                      help='Минимальная длительность тишины (мс)')
    parser.add_argument('--speech-pad', '-p', type=int, default=config.vad.SPEECH_PAD_MS,
                      help='Padding речи (мс)')
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
    required_envs = ['YANDEX_FOLDER_ID', 'YANDEX_OAUTH_TOKEN', 'YANDEX_API_KEY']
    missing = [env for env in required_envs if not os.getenv(env)]

    if missing:
        error(f"Отсутствуют переменные окружения: {', '.join(missing)}")
        error("Проверь shell.nix!")
        return False

    return True

def main():
    args = parse_args()

    if args.debug:
        config.enable_debug()
        set_debug(True)
        debug("🔧 Режим отладки включен")

    if not check_environment():
        sys.exit(1)

    info("🎤 Запускаю Жору...")

    global jora
    jora = Jora(args)
    signal.signal(signal.SIGINT, signal_handler)

    log_timing("Инициализация завершена")

    try:
        info("👂 Слушаю команды...")
        jora.run()
    except Exception as e:
        error(f"Критическая ошибка: {e}")
        sys.exit(1)
    finally:
        if jora:
            jora.stop()

if __name__ == "__main__":
    main()
