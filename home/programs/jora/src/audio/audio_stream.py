import sounddevice as sd # type: ignore
import numpy as np # type: ignore
from typing import Optional, Tuple
from src.utils.logger import error
from src.utils.config import config

class BaseAudioStream:
    """Базовый класс для аудио потока"""

    def __init__(self, channels: int, rate: int, chunk: int, dtype: str):
        """Инициализация аудио потока"""
        self._stream: Optional[sd.InputStream] = None
        self.channels = channels
        self.rate = rate
        self.chunk = chunk
        self.dtype = dtype

        if not self.initialize_stream():
            raise RuntimeError("Не удалось инициализировать аудио поток")

    @property
    def is_active(self) -> bool:
        """Проверка активности потока"""
        return self._stream is not None and self._stream.active

    def initialize_stream(self) -> bool:
        """Инициализация потока"""
        try:
            self._stream = sd.InputStream(
                channels=self.channels,
                samplerate=self.rate,
                blocksize=self.chunk,
                dtype=self.dtype
            )
            if self._stream is not None:
                self._stream.start()
                return True
            return False

        except Exception as e:
            error(f"Ошибка инициализации аудио потока: {e}")
            self._stream = None
            return False

    def read(self) -> Tuple[np.ndarray, bool]:
        """Чтение данных из потока"""
        if not self.is_active:
            if not self.initialize_stream():
                return np.array([]), True

        try:
            assert self._stream is not None
            data, overflow = self._stream.read(self.chunk)
            return data.reshape(-1), overflow

        except Exception as e:
            error(f"Ошибка чтения из потока: {e}")
            self._stream = None
            return np.array([]), True

    def cleanup(self) -> None:
        """Очистка ресурсов"""
        if self._stream is not None:
            try:
                self._stream.stop()
                self._stream.close()
                self._stream = None
            except Exception as e:
                error(f"Ошибка при очистке потока: {e}")

    def __del__(self) -> None:
        """Деструктор"""
        self.cleanup()

    def __enter__(self) -> 'BaseAudioStream':
        """Контекстный менеджер - вход"""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Контекстный менеджер - выход"""
        self.cleanup()

class VADStream(BaseAudioStream):
    """Аудио поток для детектора речи"""

    def __init__(self):
        super().__init__(
            channels=config.vad.CHANNELS,
            rate=config.vad.RATE,
            chunk=config.vad.CHUNK,
            dtype=config.vad.FORMAT
        )

class RecorderStream(BaseAudioStream):
    """Аудио поток для записи"""

    def __init__(self):
        super().__init__(
            channels=config.recorder.CHANNELS,
            rate=config.recorder.RATE,
            chunk=config.recorder.CHUNK,
            dtype=config.recorder.FORMAT
        )
