import logging
from typing import Optional
import time

class JoraLogger:
    def __init__(self):
        self.formatter = logging.Formatter('%(message)s')
        self.console_handler = logging.StreamHandler()
        self.console_handler.setFormatter(self.formatter)

        self.logger = logging.getLogger('jora')
        self.logger.addHandler(self.console_handler)
        self.logger.setLevel(logging.INFO)

        self._start_time: Optional[float] = None
        self._last_time: Optional[float] = None

    def start_timer(self):
        """Запуск таймера"""
        self._start_time = time.time()
        self._last_time = self._start_time

    def log_timing(self, msg: str):
        """Логирование времени с начала запуска"""
        if not self._start_time or not self._last_time:
            return

        current = time.time()
        delta = (current - self._last_time) * 1000
        self._last_time = current

        self.logger.debug(f"⏱️ {msg}: {delta:.1f}ms")

    def debug(self, msg: str):
        """Отладочное сообщение"""
        self.logger.debug(f"🔍 {msg}")

    def info(self, msg: str):
        """Пользовательское сообщение"""
        self.logger.info(msg)

    def error(self, msg: str):
        """Ошибка"""
        self.logger.error(f"❌ {msg}")

    def set_debug(self, enabled: bool):
        """Установка режима отладки"""
        self.logger.setLevel(logging.DEBUG if enabled else logging.INFO)
        if enabled:
            self.start_timer()

# Глобальный логгер
logger = JoraLogger()

# Экспортируем методы для совместимости
debug = logger.debug
info = logger.info
error = logger.error
set_debug = logger.set_debug
log_timing = logger.log_timing
