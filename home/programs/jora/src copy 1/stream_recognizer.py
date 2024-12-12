import pyaudio  # type: ignore
import grpc  # type: ignore
import os
from yandex.cloud.ai.stt.v3 import stt_pb2  # type: ignore
from yandex.cloud.ai.stt.v3 import stt_service_pb2_grpc  # type: ignore

class StreamRecognizer:
    def __init__(self):
        self.FORMAT = pyaudio.paInt16
        self.CHANNELS = 1
        self.RATE = 8000
        self.CHUNK = 4096
        self.audio = pyaudio.PyAudio()
        self.api_key = os.getenv('JORA_API_KEY')

    def _get_streaming_options(self):
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
                    profanity_filter=False,  # Жора не стесняется 😎
                    literature_text=False
                ),
                language_restriction=stt_pb2.LanguageRestrictionOptions(
                    restriction_type=stt_pb2.LanguageRestrictionOptions.WHITELIST,
                    language_code=['ru-RU']
                ),
                audio_processing_type=stt_pb2.RecognitionModelOptions.REAL_TIME
            )
        )

    def recognize_stream(self, duration=5):
        cred = grpc.ssl_channel_credentials()
        channel = grpc.secure_channel('stt.api.cloud.yandex.net:443', cred)
        stub = stt_service_pb2_grpc.RecognizerStub(channel)

        def audio_gen():
            yield stt_pb2.StreamingRequest(session_options=self._get_streaming_options())

            stream = self.audio.open(
                format=self.FORMAT,
                channels=self.CHANNELS,
                rate=self.RATE,
                input=True,
                frames_per_buffer=self.CHUNK
            )

            print("🎙️ Слушаю тебя, братишка...")

            for _ in range(0, int(self.RATE / self.CHUNK * duration)):
                data = stream.read(self.CHUNK)
                yield stt_pb2.StreamingRequest(chunk=stt_pb2.AudioChunk(data=data))

            stream.stop_stream()
            stream.close()

        responses = stub.RecognizeStreaming(
            audio_gen(),
            metadata=[('authorization', f'Api-Key {self.api_key}')]
        )

        result = []
        try:
            for response in responses:
                event_type = response.WhichOneof('Event')
                if event_type == 'final':
                    alternatives = [a.text for a in response.final.alternatives]
                    if alternatives:
                        result.append(alternatives[0])
        except grpc._channel._Rendezvous as err:
            print(f'⚠️ Ошибка: {err._state.details}')

        return ' '.join(result)
