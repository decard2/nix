import pyaudio # type: ignore
import wave
import urllib.request
import json
import os
import tempfile
import subprocess
import numpy as np # type: ignore
import noisereduce as nr # type: ignore
from datetime import datetime, timedelta

class SpeechRecognizer:
    def __init__(self):
        # Базовые параметры аудио
        self.FORMAT = pyaudio.paInt16
        self.CHANNELS = 1
        self.RATE = 16000
        self.CHUNK = 1024

        # Параметры записи и детекции тишины
        self.MAX_DURATION = 5  # максимальная длительность записи в секундах
        self.SILENCE_THRESHOLD = 1000  # порог тишины
        self.SILENCE_DURATION = 0.5  # длительность тишины для остановки в секундах

        # Параметры шумодава
        self.NOISE_REDUCE_STRENGTH = 0.5  # сила шумоподавления (0.0 - 1.0)

        self.audio = pyaudio.PyAudio()

        # Загружаем токены из окружения
        self.folder_id = os.getenv("YANDEX_FOLDER_ID")
        self.oauth_token = os.getenv("YANDEX_OAUTH_TOKEN")
        self.iam_token = None
        self.token_expires = None

        # Сразу получаем IAM токен
        self.get_iam_token()

    def get_iam_token(self):
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
                decoded_response = json.loads(response.read().decode('utf-8'))

                self.iam_token = decoded_response.get('iamToken')
                self.token_expires = datetime.now() + timedelta(hours=11)

                print("✅ IAM токен успешно обновлен!")

            except Exception as e:
                print(f"⚠️ Ошибка получения IAM токена: {str(e)}")
                raise

    def is_silence(self, data, silence_threshold=None):
        """Проверяет, является ли фрагмент тишиной"""
        threshold = silence_threshold if silence_threshold else self.SILENCE_THRESHOLD
        try:
            values = np.frombuffer(data, dtype=np.int16)
            energy = np.mean(np.abs(values))
            return energy < threshold
        except Exception as e:
            print(f"⚠️ Ошибка определения тишины: {str(e)}")
            return False

    def recognize_stream(self):
        temp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        temp_ogg = tempfile.NamedTemporaryFile(suffix=".ogg", delete=False)

        stream = self.audio.open(
            format=self.FORMAT,
            channels=self.CHANNELS,
            rate=self.RATE,
            input=True,
            frames_per_buffer=self.CHUNK
        )

        frames = []
        silence_frames = 0
        max_silence_frames = int(self.SILENCE_DURATION * self.RATE / self.CHUNK)

        print("🎙️ Записываю...")

        frames_limit = int(self.MAX_DURATION * self.RATE / self.CHUNK)
        while len(frames) < frames_limit:
            data = stream.read(self.CHUNK)
            frames.append(data)

            if self.is_silence(data):
                silence_frames += 1
                if silence_frames >= max_silence_frames:
                    break
            else:
                silence_frames = 0

        stream.stop_stream()
        stream.close()

        audio_data = np.frombuffer(b''.join(frames), dtype=np.int16)

        print("🔇 Убираю шум...")
        try:
            audio_float = audio_data.astype(float) / 32768.0

            reduced_noise = nr.reduce_noise(
                y=audio_float,
                sr=self.RATE,
                stationary=True,
                prop_decrease=self.NOISE_REDUCE_STRENGTH
            )

            processed_audio = (reduced_noise * 32767).astype(np.int16)

        except Exception as e:
            print(f"⚠️ Ошибка шумоподавления: {str(e)}")
            processed_audio = audio_data

        # Сохраняем в WAV
        with wave.open(temp_wav.name, 'wb') as wf:
            wf.setnchannels(self.CHANNELS)
            wf.setsampwidth(self.audio.get_sample_size(self.FORMAT))
            wf.setframerate(self.RATE)
            wf.writeframes(processed_audio.tobytes())

        # Конвертируем в OGG
        try:
            subprocess.run([
                'opusenc',
                '--bitrate', '48',
                temp_wav.name,
                temp_ogg.name
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError as e:
            print(f"⚠️ Ошибка конвертации в OGG: {str(e)}")
            return ""

        # Отправляем на распознавание
        try:
            with open(temp_ogg.name, "rb") as f:
                data = f.read()

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
            decoded_data = json.loads(response)

            if decoded_data.get("error_code") is None:
                return decoded_data.get("result", "")
            else:
                print(f"⚠️ Ошибка распознавания: {decoded_data}")
                return ""

        except Exception as e:
            print(f"⚠️ Ошибка: {str(e)}")
            return ""

        finally:
            # Удаляем временные файлы
            os.unlink(temp_wav.name)
            os.unlink(temp_ogg.name)
