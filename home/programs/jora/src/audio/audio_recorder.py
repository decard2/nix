import tempfile
import os
from typing import Optional, List
import numpy as np # type: ignore
import soundfile as sf # type: ignore
from src.utils.logger import error
from src.utils.config import config
from src.audio.audio_stream import RecorderStream

class AudioRecorder:
    """Класс для записи аудио в файл"""

    def __init__(self):
        self.temp_file: Optional[str] = None
        self.writer: Optional[sf.SoundFile] = None
        self.stream: Optional[RecorderStream] = None
        self.is_recording: bool = False
        self.buffer: List[np.ndarray] = []

    def _convert_format(self, audio: np.ndarray) -> np.ndarray:
        """Конвертирует float32 [-1.0, 1.0] в int16 [-32768, 32767]"""
        if audio.dtype == np.float32:
            return (audio * 32767).astype(np.int16)
        return audio

    def start_recording(self, initial_audio: Optional[np.ndarray] = None) -> bool:
        """Начинает запись во временный файл"""
        try:
            temp = tempfile.NamedTemporaryFile(suffix='.ogg', delete=False)
            self.temp_file = temp.name
            temp.close()

            self.writer = sf.SoundFile(
                self.temp_file,
                mode='w',
                samplerate=config.recorder.RATE,
                channels=config.recorder.CHANNELS,
                format=config.recorder.RECORD_FORMAT,
                subtype=config.recorder.RECORD_SUBTYPE
            )

            self.stream = RecorderStream()
            self.is_recording = True
            self.buffer = []

            if initial_audio is not None:
                converted_audio = self._convert_format(initial_audio)
                self.buffer.append(converted_audio)

            return True

        except Exception as e:
            error(f"Ошибка начала записи: {e}")
            self.cleanup()
            return False

    def process(self) -> bool:
        """Записывает текущий чанк аудио в буфер"""
        if not self.is_recording or not self.stream:
            return False

        try:
            audio, overflow = self.stream.read()
            if overflow:
                return False

            converted_audio = self._convert_format(audio)
            self.buffer.append(converted_audio)
            return True

        except Exception as e:
            error(f"Ошибка записи аудио: {e}")
            return False

    def stop_recording(self):
        """Останавливает запись и возвращает путь к файлу"""
        if not self.writer or not self.is_recording:
            return None

        try:
            if self.buffer:
                audio_data = np.concatenate(self.buffer)
                self.writer.write(audio_data)

            self.writer.close()
            self.writer = None
            self.is_recording = False

            if self.stream:
                self.stream.cleanup()
                self.stream = None
            self.buffer = []

            return self.temp_file

        except Exception as e:
            error(f"Ошибка остановки записи: {e}")
            return None

    def cleanup(self):
        """Очищает ресурсы и удаляет временный файл"""
        self.is_recording = False

        if self.stream:
            self.stream.cleanup()
            self.stream = None

        if self.writer:
            try:
                self.writer.close()
            except:
                pass
            self.writer = None

        if self.temp_file and os.path.exists(self.temp_file):
            try:
                os.unlink(self.temp_file)
            except Exception as e:
                error(f"Ошибка удаления файла: {e}")
            self.temp_file = None

        self.buffer = []

    def __del__(self):
        self.cleanup()

    def __enter__(self):
        self.start_recording()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.cleanup()
