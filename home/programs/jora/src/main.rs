mod commands;

use anyhow::Result;
use commands::Commands;
use std::io::Cursor;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};
use voice_stream::cpal::traits::StreamTrait;
use voice_stream::VoiceStream;

fn create_wav_buffer(samples: &[f32]) -> Result<Vec<u8>> {
    let mut buffer = Cursor::new(Vec::new());
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate: 16000,
        bits_per_sample: 32,
        sample_format: hound::SampleFormat::Float,
    };

    {
        let mut writer = hound::WavWriter::new(&mut buffer, spec)?;
        for &sample in samples {
            writer.write_sample(sample)?;
        }
        writer.finalize()?;
    }

    Ok(buffer.into_inner())
}

fn main() -> Result<()> {
    println!("Слушаю, братан...");

    let (voice_stream, receiver) = VoiceStream::default_device().expect("Микрофон не найден, чёт!");
    let samples_buffer = Arc::new(Mutex::new(Vec::new()));
    let samples_buffer_clone = samples_buffer.clone();
    let mut dictation_mode = false;

    let client = reqwest::blocking::Client::new();

    voice_stream.play()?;

    let mut last_print = Instant::now();
    let mut samples_received = 0;

    loop {
        match receiver.try_recv() {
            Ok(voice_data) => {
                samples_received += voice_data.len();

                if last_print.elapsed() >= Duration::from_secs(1) {
                    println!("Получено сэмплов за секунду: {}", samples_received);
                    samples_received = 0;
                    last_print = Instant::now();
                }

                let mut samples = samples_buffer_clone.lock().unwrap();
                samples.extend(voice_data);

                if samples.len() > 5000 {
                    println!("Буфер заполнен, размер: {}", samples.len());
                    let start = Instant::now();

                    let wav_data = create_wav_buffer(&samples)?;

                    let form = reqwest::blocking::multipart::Form::new().part(
                        "file",
                        reqwest::blocking::multipart::Part::bytes(wav_data)
                            .file_name("audio.wav")
                            .mime_str("audio/wav")?,
                    );

                    if let Ok(response) = client
                        .post("http://localhost:8000/v1/audio/transcriptions")
                        .multipart(form)
                        .send()
                    {
                        println!("Отправка и получение ответа заняла: {:?}", start.elapsed());
                        if let Ok(text) = response.text() {
                            println!("Распознано: {}", text);

                            if let Some(cmd_result) =
                                Commands::execute_command(&text, dictation_mode)
                            {
                                if cmd_result == "DICTATION_MODE" {
                                    dictation_mode = !dictation_mode;
                                    println!(
                                        "Режим диктовки {}",
                                        if dictation_mode {
                                            "включен"
                                        } else {
                                            "выключен"
                                        }
                                    );
                                }
                            }
                        }
                    }
                    samples.clear();
                }
            }
            Err(_) => {
                thread::sleep(Duration::from_millis(100));
            }
        }
    }
}
