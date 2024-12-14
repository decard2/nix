from dataclasses import dataclass, field

@dataclass
class VADConfig:
    """Конфигурация для детектора речи"""
    CHANNELS: int = 1
    RATE: int = 16000
    CHUNK: int = 512
    FORMAT: str = 'float32'

@dataclass
class RecorderConfig:
    """Конфигурация для записи"""
    CHANNELS: int = 1
    RATE: int = 16000
    CHUNK: int = 512
    FORMAT: str = 'int16'
    RECORD_FORMAT: str = 'OGG'
    RECORD_SUBTYPE: str = 'OPUS'

@dataclass
class Config:
    DEBUG: bool = False
    vad: VADConfig = field(default_factory=VADConfig)
    recorder: RecorderConfig = field(default_factory=RecorderConfig)

    def enable_debug(self):
        """Включает режим отладки"""
        self.DEBUG = True

# Глобальный конфиг
config = Config()
