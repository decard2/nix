import pyaudio # type: ignore
import wave
import urllib.request
import json
import os
import tempfile
import subprocess
from datetime import datetime, timedelta

class SpeechRecognizer:
    def __init__(self):
        # Параметры аудио
        self.FORMAT = pyaudio.paInt16
        self.CHANNELS = 1
        self.RATE = 16000
        self.CHUNK = 1024

        # Максимальная тишина для остановки записи (в чанках)
        self.MAX_SILENCE_CHUNKS = int(self.RATE / self.CHUNK * 0.5)  # 0.5 сек

        self.audio = pyaudio.PyAudio()

        # Яндекс токены
        self.folder_id = os.getenv("YANDEX_FOLDER_ID")
        self.oauth_token = os.getenv("YANDEX_OAUTH_TOKEN")
        self.iam_token = None
        self.token_expires = None

        # Сразу получаем IAM токен
        self._update_iam_token()

    def _update_iam_token(self):
        """Обновляет IAM токен если нужно"""
        if (self.iam_token is None or
            self.token_expires is None or
            datetime.now() >= self.token_expires):

            print("🔄 Обновляю IAM токен...")

            url = "https://iam.api.cloud.yandex.net/iam/v1/tokens"
            data = json.dumps({"yandexPassportOauthToken": self.oauth_token}).encode('utf-8')

            request = urllib.request.Request(
                url,
                data=data,
                headers={'Content-Type': 'application/json'}
            )

            try:
                response = urllib.request.urlopen(request)
                decoded = json.loads(response.read().decode('utf-8'))

                self.iam_token = decoded.get('iamToken')
                self.token_expires = datetime.now() + timedelta(hours=11)

                print("✅ IAM токен обновлен!")

            except Exception as e:
                print(f"❌ Ошибка получения IAM токена: {e}")
                raise

    def record_until_silence(self, detector) -> str:
        """Записывает аудио пока детектор слышит речь"""
        temp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        temp_ogg = tempfile.NamedTemporaryFile(suffix=".ogg", delete=False)

        try:
            # Открываем поток для записи
            stream = self.audio.open(
                format=self.FORMAT,
                channels=self.CHANNELS,
                rate=self.RATE,
                input=True,
                frames_per_buffer=self.CHUNK
            )

            print("🎙️ Записываю...")
            frames = []
            silence_chunks = 0

            # Записываем пока слышим речь
            while True:
                data = stream.read(self.CHUNK)
                frames.append(data)

                if not detector.is_speech():
                    silence_chunks += 1
                    if silence_chunks >= self.MAX_SILENCE_CHUNKS:
                        break
                else:
                    silence_chunks = 0

            print("✅ Запись завершена")

            # Если записи нет или она слишком короткая
            if len(frames) < 3:  # меньше 3 чанков считаем шумом
                return ""

            # Закрываем поток
            stream.stop_stream()
            stream.close()

            # Сохраняем WAV
            with wave.open(temp_wav.name, 'wb') as wf:
                wf.setnchannels(self.CHANNELS)
                wf.setsampwidth(self.audio.get_sample_size(self.FORMAT))
                wf.setframerate(self.RATE)
                wf.writeframes(b''.join(frames))

            # Конвертируем в OGG
            subprocess.run([
                'opusenc',
                '--bitrate', '48',
                temp_wav.name,
                temp_ogg.name
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # Отправляем на распознавание
            with open(temp_ogg.name, "rb") as f:
                data = f.read()

            # Обновляем токен если нужно
            self._update_iam_token()

            params = "&".join([
                "topic=general",
                f"folderId={self.folder_id}",
                "lang=ru-RU"
            ])

            url = urllib.request.Request(
                f"https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?{params}",
                data=data
            )
            url.add_header("Authorization", f"Bearer {self.iam_token}")

            response = urllib.request.urlopen(url).read().decode('UTF-8')
            decoded = json.loads(response)

            return decoded.get("result", "")

        except Exception as e:
            print(f"❌ Ошибка записи/распознавания: {e}")
            return ""

        finally:
            # Удаляем временные файлы
            os.unlink(temp_wav.name)
            os.unlink(temp_ogg.name)

    def __del__(self):
        """Освобождаем ресурсы при удалении объекта"""
        self.audio.terminate()
