import time
import numpy as np# type: ignore
from typing import Optional, Dict, Any, List
from silero_vad import load_silero_vad, VADIterator  # type: ignore

from src.utils.logger import debug, error
from src.utils.config import config
from src.audio.audio_stream import VADStream

class VoiceDetector:
    """Детектор голосовой активности на базе Silero VAD"""

    def __init__(self,
                 sensitivity: float = 0.5,
                 min_silence_ms: int = 100,
                 speech_pad_ms: int = 30):
        """Инициализация детектора"""
        start_time = time.time()

        self.sensitivity = sensitivity
        self.min_silence_ms = min_silence_ms
        self.speech_pad_ms = speech_pad_ms

        # Размер буфера в сэмплах (speech_pad + запас)
        self.buffer_size = int(config.vad.RATE * (speech_pad_ms + 50) / 1000)
        self.audio_buffer: List[np.ndarray] = []

        # Флаг активной речи
        self.is_speech_active = False

        # Создаем поток для VAD
        self.stream = VADStream()

        # Загружаем VAD модель
        debug("Загрузка Silero VAD модели...")
        model_start = time.time()
        self.model = load_silero_vad(onnx=True)
        debug(f"⏱️ Загрузка VAD модели: {(time.time() - model_start)*1000:.1f}ms")

        # Создаем VAD итератор
        self.vad_iterator = VADIterator(
            model=self.model,
            threshold=self.sensitivity,
            sampling_rate=config.vad.RATE,
            min_silence_duration_ms=min_silence_ms,
            speech_pad_ms=speech_pad_ms
        )

        # Логируем параметры
        debug("🛠️ Параметры детектора:")
        debug(f"   📊 Чувствительность: {sensitivity}")
        debug(f"   🔇 Мин. тишина: {min_silence_ms}ms")
        debug(f"   📏 Padding речи: {speech_pad_ms}ms")
        debug(f"   🎵 Частота дискретизации: {config.vad.RATE} Hz")
        debug(f"   📦 Размер чанка: {config.vad.CHUNK} samples")
        debug(f"   ⏱️ Длина чанка: {config.vad.CHUNK/config.vad.RATE*1000:.1f} ms")
        debug(f"   💾 Размер буфера: {self.buffer_size} samples ({self.buffer_size/config.vad.RATE*1000:.1f} ms)")

        debug(f"⏱️ Общее время инициализации: {(time.time() - start_time)*1000:.1f}ms")

    def process_audio(self) -> Optional[Dict[str, Any]]:
        """Обрабатывает аудио и возвращает состояние с аудио данными"""
        try:
            audio, overflow = self.stream.read()
            if overflow:
                return None

            # Добавляем в буфер
            self.audio_buffer.append(audio)

            # Поддерживаем размер буфера
            while len(self.audio_buffer) * len(audio) > self.buffer_size:
                self.audio_buffer.pop(0)

            # Получаем результат VAD
            speech_dict = self.vad_iterator(audio)

            if speech_dict is not None:
                debug(f"VAD вернул: {speech_dict}")

                if 'start' in speech_dict and not self.is_speech_active:
                    self.is_speech_active = True
                    debug("⭐ Детектировано начало речи")
                    return {
                        'type': 'start',
                        'audio': np.concatenate(self.audio_buffer)
                    }
                elif 'end' in speech_dict and self.is_speech_active:
                    self.is_speech_active = False
                    debug("⭐ Детектирован конец речи")
                    return {
                        'type': 'end',
                        'audio': audio  # Последний чанк
                    }

            return None

        except Exception as e:
            error(f"Ошибка детектора: {e}")
            return None

    def cleanup(self):
        """Очистка ресурсов"""
        self.vad_iterator.reset_states()
        self.stream.cleanup()
        self.audio_buffer.clear()

    def __del__(self):
        """Деструктор"""
        self.cleanup()
