import pyaudio
import queue
import subprocess
import time
import json
from vosk import Model, KaldiRecognizer # type: ignore
from colors import Colors

CHUNK_SIZE = 8000
audio_queue = queue.Queue(maxsize=5)

def start_recording():
    p = pyaudio.PyAudio()

    command = [
        'ffmpeg',
        '-f', 'pulse',
        '-i', 'default',
        '-af', 'highpass=f=200,lowpass=f=3000,volume=1.5',
        '-acodec', 'pcm_s16le',
        '-ar', '16000',
        '-ac', '1',
        '-f', 's16le',
        '-'
    ]

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL
    )

    def callback(in_data, frame_count, time_info, status):
        try:
            if process.stdout is None:
                return (b'', pyaudio.paContinue)

            data = process.stdout.read(frame_count * 2)
            if len(data) > 0:
                try:
                    audio_queue.put(data, block=False)
                except queue.Full:
                    audio_queue.get_nowait()  # Освобождаем место
                    audio_queue.put(data, block=False)
                return (data, pyaudio.paContinue)
        except Exception as e:
            print(f"{Colors.FAIL}Ошибка в callback: {e}{Colors.END}")

        return (b'', pyaudio.paContinue)

    stream = p.open(
        format=pyaudio.paInt16,
        channels=1,
        rate=16000,
        input=True,
        frames_per_buffer=CHUNK_SIZE,
        stream_callback=callback,
        start=True  # Явно стартуем стрим
    )

    # Даём время на инициализацию
    time.sleep(0.2)
    return stream, p, process

def process_audio():
    print(f"{Colors.BLUE}🎤 Инициализация модели распознавания...{Colors.END}")
    model = Model("model-ru")
    print(f"{Colors.GREEN}✅ Модель загружена{Colors.END}")

    rec = KaldiRecognizer(model, 16000)
    buffer = b""

    while True:
        try:
            # Уменьшаем таймаут и добавляем неблокирующее получение
            try:
                data = audio_queue.get(timeout=0.1)
            except queue.Empty:
                continue

            if len(data) == 0:
                continue

            buffer += data

            if len(buffer) >= CHUNK_SIZE:
                if rec.AcceptWaveform(buffer):
                    result = rec.Result()
                    if len(result) > 2:  # Проверяем, что результат не пустой
                        parsed = json.loads(result)
                        if len(parsed["text"].strip()) > 0:
                            yield result
                buffer = buffer[-2000:]  # Оставляем хвост для следующей итерации

            # Обрабатываем промежуточный результат
            partial = rec.PartialResult()
            if len(partial) > 2:
                print(f"{Colors.BLUE}👂 Слушаю...{Colors.END}", end="\r")

        except Exception as e:
            print(f"{Colors.FAIL}❌ Ошибка распознавания: {e}{Colors.END}")
            buffer = b""  # Сбрасываем буфер при ошибке
            continue
