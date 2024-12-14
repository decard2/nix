import pyaudio  # type: ignore
import grpc  # type: ignore
import os
import subprocess
import wave
import tempfile
from datetime import datetime
from typing import Generator
from yandex.cloud.ai.stt.v3 import stt_pb2  # type: ignore
from yandex.cloud.ai.stt.v3 import stt_service_pb2_grpc  # type: ignore

class StreamRecognizer:
    def __init__(self):
        self.FORMAT = pyaudio.paInt16
        self.CHANNELS = 1
        self.RATE = 8000
        self.CHUNK = 4096
        self.audio = pyaudio.PyAudio()
        self.api_key = os.getenv('YANDEX_API_KEY')
        self.stream = None
        self.is_initialized = False
        self.previous_text = ""
        self.should_stop = False
        self.is_first_phrase = True
        self.debug = os.getenv("JORA_DEBUG") == "1"

        # Буфер для накопления начальных чанков
        self.initial_buffer = []
        self.BUFFER_SIZE = 5  # Сколько чанков буферизируем перед отправкой

    def _debug_save_and_play(self, audio_data: bytes):
        """Сохраняет и воспроизводит аудио в режиме отладки"""
        try:
            # Создаём временный WAV файл
            temp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
            with wave.open(temp_wav.name, 'wb') as wf:
                wf.setnchannels(self.CHANNELS)
                wf.setsampwidth(self.audio.get_sample_size(self.FORMAT))
                wf.setframerate(self.RATE)
                wf.writeframes(audio_data)

            # Копируем в debug_records
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            debug_file = f"debug_records/stream_{timestamp}.wav"
            subprocess.run(['cp', temp_wav.name, debug_file], check=True)
            print(f"🔍 Сохранил стрим: {debug_file}")

            # Воспроизводим
            subprocess.run(['play', '-q', temp_wav.name], check=True)

            # Удаляем временные файлы и дебаг запись
            os.unlink(temp_wav.name)
            os.unlink(debug_file)

        except Exception as e:
            print(f"⚠️ Ошибка отладки: {e}")

    def get_streaming_options(self) -> stt_pb2.StreamingOptions:
        """Возвращает настройки для стримингового распознавания"""
        return stt_pb2.StreamingOptions(
            recognition_model=stt_pb2.RecognitionModelOptions(
                audio_format=stt_pb2.AudioFormatOptions(
                    raw_audio=stt_pb2.RawAudio(
                        audio_encoding=stt_pb2.RawAudio.LINEAR16_PCM,
                        sample_rate_hertz=8000,
                        audio_channel_count=1
                    )
                ),
                text_normalization=stt_pb2.TextNormalizationOptions(
                    text_normalization=stt_pb2.TextNormalizationOptions.TEXT_NORMALIZATION_ENABLED,
                    profanity_filter=False,
                    literature_text=True
                ),
                language_restriction=stt_pb2.LanguageRestrictionOptions(
                    restriction_type=stt_pb2.LanguageRestrictionOptions.WHITELIST,
                    language_code=['ru-RU']
                ),
                audio_processing_type=stt_pb2.RecognitionModelOptions.REAL_TIME
            ),
            eou_classifier=stt_pb2.EouClassifierOptions(
                default_classifier=stt_pb2.DefaultEouClassifier(
                    type=stt_pb2.DefaultEouClassifier.HIGH,
                    max_pause_between_words_hint_ms=1000
                )
            )
        )

    def initialize_stream(self) -> bool:
        """Инициализация потока"""
        try:
            if self.stream is None:
                print("🎙️ Инициализирую поток...")
                self.stream = self.audio.open(
                    format=self.FORMAT,
                    channels=self.CHANNELS,
                    rate=self.RATE,
                    input=True,
                    frames_per_buffer=self.CHUNK
                )
                self.stream.start_stream()
                self.is_initialized = True
                print("🎙️ Поток готов!")
            return True
        except Exception as e:
            print(f"⚠️ Ошибка инициализации потока: {e}")
            self.is_initialized = False
            return False

    def emulate_typing(self, text: str):
        """Эмулирует печать текста через wtype"""
        try:
            if not self.is_first_phrase:
                subprocess.run(['wtype', ' ' + text], check=True)
            else:
                subprocess.run(['wtype', text], check=True)
                self.is_first_phrase = False
        except Exception as e:
            print(f"⚠️ Ошибка эмуляции печати: {e}")

    def audio_generator(self) -> Generator[stt_pb2.StreamingRequest, None, None]:
        """Генератор аудио данных"""
        if not self.initialize_stream():
            print("❌ Не удалось инициализировать поток!")
            return

        # Отправляем настройки
        yield stt_pb2.StreamingRequest(session_options=self.get_streaming_options())

        try:
            # Сначала накапливаем буфер
            print("🎙️ Накапливаю буфер...")
            self.initial_buffer = []
            all_data = bytes()  # Для дебаг режима

            for _ in range(self.BUFFER_SIZE):
                if self.stream:
                    data = self.stream.read(self.CHUNK, exception_on_overflow=False)
                    self.initial_buffer.append(data)
                    if self.debug:
                        all_data += data

            # В режиме отладки воспроизводим накопленный буфер
            if self.debug and all_data:
                self._debug_save_and_play(all_data)

            # Отправляем накопленный буфер
            for data in self.initial_buffer:
                yield stt_pb2.StreamingRequest(chunk=stt_pb2.AudioChunk(data=data))

            # Теперь стримим в реальном времени
            print("🎙️ Слушаю тебя, братишка...")
            debug_buffer = bytes()  # Буфер для дебаг режима

            while not self.should_stop:
                if self.stream:
                    data = self.stream.read(self.CHUNK, exception_on_overflow=False)
                    if self.debug:
                        debug_buffer += data
                        # Каждые 2 секунды воспроизводим в дебаг режиме
                        if len(debug_buffer) >= self.RATE * 2:
                            self._debug_save_and_play(debug_buffer)
                            debug_buffer = bytes()
                    yield stt_pb2.StreamingRequest(chunk=stt_pb2.AudioChunk(data=data))

        except Exception as e:
            print(f"⚠️ Ошибка потока: {e}")
        finally:
            self.cleanup()

    def recognize_stream(self) -> None:
        self.should_stop = False
        cred = grpc.ssl_channel_credentials()
        channel = grpc.secure_channel('stt.api.cloud.yandex.net:443', cred)
        stub = stt_service_pb2_grpc.RecognizerStub(channel)

        responses = stub.RecognizeStreaming(
            self.audio_generator(),
            metadata=[('authorization', f'Api-Key {self.api_key}')]
        )

        current_text = ""
        partial_text = ""

        try:
            for response in responses:
                if self.should_stop:
                    break

                event_type = response.WhichOneof('Event')

                if event_type == 'partial':
                    if len(response.partial.alternatives) > 0:
                        partial_text = response.partial.alternatives[0].text
                        print(f"\r🎯 {partial_text:<60}", end='', flush=True)

                elif event_type == 'final_refinement':
                    if len(response.final_refinement.normalized_text.alternatives) > 0:
                        text = response.final_refinement.normalized_text.alternatives[0].text

                        if text.strip().lower() == "завершить запись.":
                            print("\n✅ Команда завершения получена!")
                            self.stop()
                            return

                        if text and text != current_text:
                            print("\r" + " " * (len(partial_text) + 60), end='\r')
                            self.emulate_typing(text)
                            current_text = text
                            print(f"\r📝 {text}")

        except Exception as e:
            print(f"\n⚠️ Ошибка: {str(e)}")
        finally:
            self.cleanup()
            channel.close()
            self.is_first_phrase = True

    def stop(self):
        """Метод для корректной остановки"""
        if self.stream:
            try:
                self.should_stop = True
                import time
                time.sleep(0.1)
                self.cleanup()
                self.is_first_phrase = True
            except Exception as e:
                print(f"⚠️ Ошибка при остановке: {e}")

    def cleanup(self):
        """Очистка ресурсов потока"""
        if self.stream:
            try:
                self.stream.stop_stream()
                self.stream.close()
                self.stream = None
                import time
                time.sleep(0.1)
            except Exception as e:
                print(f"⚠️ Ошибка при очистке потока: {e}")
            finally:
                self.is_initialized = False

    def __del__(self):
        """Освобождаем ресурсы при удалении объекта"""
        self.cleanup()
        if self.audio:
            self.audio.terminate()
