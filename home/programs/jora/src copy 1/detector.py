import torch # type: ignore
import sounddevice as sd # type: ignore
import numpy as np # type: ignore

class VoiceDetector:
    def __init__(self, sensitivity: float = 0.5):
        # Параметры аудио
        self.rate = 16000
        self.chunk = 512  # Размер чанка для Silero
        self.sensitivity = sensitivity  # Порог чувствительности

        # Инициализация Silero VAD
        torch.set_num_threads(1)
        self.model, _ = torch.hub.load(
            repo_or_dir='snakers4/silero-vad',
            model='silero_vad',
            force_reload=False
        )
        self.model.eval()

        # Инициализация аудио потока
        self.stream = sd.InputStream(
            channels=1,
            samplerate=self.rate,
            blocksize=self.chunk,
            dtype=np.float32
        )
        self.stream.start()

        print(f"✅ Детектор речи готов! Чувствительность: {self.sensitivity}")

    def is_speech(self) -> bool:
        """Проверяет наличие речи в текущем аудио потоке"""
        try:
            # Читаем чанк из потока
            audio_chunk, overflow = self.stream.read(self.chunk)
            if overflow:
                print("⚠️ Переполнение буфера!")

            # Преобразуем в нужный формат для модели
            audio = audio_chunk.reshape(-1)
            tensor = torch.FloatTensor(audio)

            # Получаем вероятность наличия речи
            with torch.no_grad():
                speech_prob = self.model(tensor, self.rate).item()

            return speech_prob > self.sensitivity

        except Exception as e:
            print(f"❌ Ошибка определения речи: {e}")
            return False

    def __del__(self):
        """Освобождаем ресурсы при удалении объекта"""
        try:
            self.stream.stop()
            self.stream.close()
        except:
            pass
