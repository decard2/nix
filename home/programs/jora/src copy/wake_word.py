import pvporcupine # type: ignore
import pyaudio # type: ignore
import struct
import os

class WakeWordDetector:
    def __init__(self):
        self.KEYWORD_PATH = os.path.join(os.path.dirname(__file__), "Давай_ru_linux_v3_0_0.ppn")
        self.MODEL_PATH = os.path.join(os.path.dirname(__file__), "porcupine_params_ru.pv")

        self.audio = pyaudio.PyAudio()
        self.porcupine = pvporcupine.create(
            access_key=os.getenv("PORCUPINE_ACCESS_KEY"),
            keyword_paths=[self.KEYWORD_PATH],
            model_path=self.MODEL_PATH
        )

        self.stream = self.audio.open(
            rate=self.porcupine.sample_rate,
            channels=1,
            format=pyaudio.paInt16,
            input=True,
            frames_per_buffer=self.porcupine.frame_length
        )

    def check_wake_word(self):
        """Проверяет наличие wake word в аудиопотоке"""
        pcm = self.stream.read(self.porcupine.frame_length)
        pcm = struct.unpack_from("h" * self.porcupine.frame_length, pcm)

        keyword_index = self.porcupine.process(pcm)
        return keyword_index >= 0

    def pause(self):
        """Приостанавливает прослушивание"""
        self.stream.stop_stream()

    def resume(self):
        """Возобновляет прослушивание"""
        self.stream.start_stream()

    def cleanup(self):
        """Освобождает ресурсы"""
        self.stream.close()
        self.audio.terminate()
        self.porcupine.delete()
