import os
import grpc # type: ignore
from typing import Generator
import numpy as np # type: ignore
from yandex.cloud.ai.stt.v3 import stt_pb2 # type: ignore
from yandex.cloud.ai.stt.v3 import stt_service_pb2_grpc # type: ignore

from src.utils.logger import debug, error
from src.utils.config import config
from src.audio.audio_stream import RecorderStream

class StreamRecognizer:
    def __init__(self):
        self.api_key = os.getenv('YANDEX_API_KEY')
        if not self.api_key:
            raise ValueError("Не установлен YANDEX_API_KEY")
        self.should_stop = False
        self.is_first_phrase = True

    def audio_generator(self) -> Generator[stt_pb2.StreamingRequest, None, None]:
        """Генератор аудио данных"""
        stream = RecorderStream()
        debug("🎙️ Поток для диктовки создан")

        # Отправляем настройки
        yield stt_pb2.StreamingRequest(session_options=self.get_streaming_options())

        try:
            while not self.should_stop:
                audio, overflow = stream.read()
                if overflow:
                    break

                # Конвертируем в int16
                if audio.dtype == np.float32:
                    audio = (audio * 32767).astype(np.int16)

                yield stt_pb2.StreamingRequest(chunk=stt_pb2.AudioChunk(data=audio.tobytes()))

        finally:
            stream.cleanup()

    def get_streaming_options(self) -> stt_pb2.StreamingOptions:
        return stt_pb2.StreamingOptions(
            recognition_model=stt_pb2.RecognitionModelOptions(
                audio_format=stt_pb2.AudioFormatOptions(
                    raw_audio=stt_pb2.RawAudio(
                        audio_encoding=stt_pb2.RawAudio.LINEAR16_PCM,
                        sample_rate_hertz=config.recorder.RATE,
                        audio_channel_count=config.recorder.CHANNELS
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
            )
        )

    def emulate_typing(self, text: str) -> bool:
        try:
            import subprocess
            if not self.is_first_phrase:
                subprocess.run(['wtype', ' ' + text], check=True)
            else:
                subprocess.run(['wtype', text], check=True)
                self.is_first_phrase = False
            return True
        except Exception as e:
            error(f"Ошибка эмуляции печати: {e}")
            return False

    def recognize_stream(self) -> None:
        """Запускает распознавание потока"""
        self.should_stop = False

        try:
            cred = grpc.ssl_channel_credentials()
            with grpc.secure_channel('stt.api.cloud.yandex.net:443', cred) as channel:
                stub = stt_service_pb2_grpc.RecognizerStub(channel)

                responses = stub.RecognizeStreaming(
                    self.audio_generator(),
                    metadata=[('authorization', f'Api-Key {self.api_key}')]
                )

                current_text = ""

                for response in responses:
                    if self.should_stop:
                        break

                    event_type = response.WhichOneof('Event')
                    if event_type == 'final_refinement':
                        if len(response.final_refinement.normalized_text.alternatives) > 0:
                            text = response.final_refinement.normalized_text.alternatives[0].text

                            if text.strip().lower() == "завершить запись.":
                                self.stop()
                                return

                            if text and text != current_text:
                                self.emulate_typing(text)
                                current_text = text

        except Exception as e:
            error(f"Ошибка распознавания: {e}")

    def stop(self):
        self.should_stop = True
