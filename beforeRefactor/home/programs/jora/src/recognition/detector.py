import numpy as np# type: ignore
from typing import Optional, Dict, Any, List
from silero_vad import load_silero_vad, VADIterator  # type: ignore

from src.utils.logger import debug, error
from src.utils.config import config
from src.audio.audio_stream import VADStream

class VoiceDetector:
    def __init__(self,
            sensitivity: float = config.vad.SENSITIVITY,
            min_silence_ms: int = config.vad.MIN_SILENCE_MS,
            speech_pad_ms: int = config.vad.SPEECH_PAD_MS):
        """Инициализация детектора"""

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
        self.model = load_silero_vad(onnx=True)

        debug("Параметры детектора:")
        debug(f"  Чувствительность: {sensitivity}")
        debug(f"  Мин. тишина: {min_silence_ms}ms")
        debug(f"  Padding речи: {speech_pad_ms}ms")

        # Создаем VAD итератор
        self.vad_iterator = VADIterator(
            model=self.model,
            threshold=self.sensitivity,
            sampling_rate=config.vad.RATE,
            min_silence_duration_ms=min_silence_ms,
            speech_pad_ms=speech_pad_ms
        )

    def process_audio(self) -> Optional[Dict[str, Any]]:
        """Обрабатывает аудио и возвращает состояние с аудио данными"""
        try:
            # Читаем новый чанк
            audio, overflow = self.stream.read()
            if overflow:
                return None

            # Добавляем в буфер
            self.audio_buffer.append(audio)

            # Получаем результат VAD
            speech_dict = self.vad_iterator(audio)

            if speech_dict is not None:

                if 'start' in speech_dict and not self.is_speech_active:
                    self.is_speech_active = True

                    # Вычисляем сколько нам нужно предыдущих чанков для паддинга
                    chunks_needed = int(config.vad.SPEECH_PAD_MS * config.vad.RATE / (1000 * len(audio)))
                    start_idx = max(0, len(self.audio_buffer) - chunks_needed)

                    # Берём нужное количество предыдущих чанков
                    padding_buffer = self.audio_buffer[start_idx:]

                    if padding_buffer:
                        return {
                            'type': 'start',
                            'audio': np.concatenate(padding_buffer)
                        }
                    else:
                        return {
                            'type': 'start',
                            'audio': audio
                        }

                elif 'end' in speech_dict and self.is_speech_active:
                    self.is_speech_active = False
                    self.audio_buffer.clear()
                    self.vad_iterator.reset_states()
                    return {
                        'type': 'end'
                    }

            # Ограничиваем размер буфера
            max_chunks = int(config.vad.SPEECH_PAD_MS * config.vad.RATE / (1000 * len(audio))) + 1
            while len(self.audio_buffer) > max_chunks:
                self.audio_buffer.pop(0)

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
