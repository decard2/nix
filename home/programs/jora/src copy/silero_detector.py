import torch # type: ignore
import sounddevice as sd # type: ignore
import numpy as np # type: ignore

class SileroVadDetector:
    def __init__(self, threshold=0.5, sampling_rate=16000):
        self.threshold = threshold
        self.sampling_rate = sampling_rate

        torch.set_num_threads(1)

        self.model, utils = torch.hub.load(
            repo_or_dir='snakers4/silero-vad',
            model='silero_vad',
            force_reload=False
        )

        self.model.eval()

        # Устанавливаем правильный размер окна для 16кГц
        self.window_size = 512  # было 1024
        self.running = True
        self.stream = sd.InputStream(
            channels=1,
            samplerate=self.sampling_rate,
            blocksize=self.window_size,
            dtype=np.float32
        )
        self.stream.start()

    def check_speech(self):
        try:
            data, overflow = self.stream.read(self.window_size)
            if overflow:
                print("⚠️ Переполнение буфера!")

            audio_chunk = data.reshape(-1)

            # Нормализация аудио
            if np.abs(audio_chunk).max() > 1.0:
                audio_chunk = np.clip(audio_chunk, -1.0, 1.0)

            tensor = torch.FloatTensor(audio_chunk)

            with torch.no_grad():
                speech_prob = self.model(tensor, self.sampling_rate).item()

            return speech_prob > self.threshold

        except Exception as e:
            print(f"🤔 Упс, ошибочка вышла: {e}")
            return False

    def pause(self):
        if self.stream.active:
            self.stream.stop()

    def resume(self):
        if not self.stream.active:
            self.stream.start()

    def cleanup(self):
        self.pause()
        self.stream.close()
