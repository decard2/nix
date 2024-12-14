import logging

# Настраиваем форматирование
formatter = logging.Formatter('%(message)s')

# Создаем handler для консоли
console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)

# Создаем логгер
logger = logging.getLogger('jora')
logger.addHandler(console_handler)
logger.setLevel(logging.INFO)  # По умолчанию INFO

def debug(msg: str):
    """Отладочное сообщение"""
    logger.debug(f"🔍 {msg}")

def info(msg: str):
    """Информационное сообщение"""
    logger.info(f"ℹ️ {msg}")

def success(msg: str):
    """Успешное действие"""
    logger.info(f"✅ {msg}")

def error(msg: str):
    """Ошибка"""
    logger.error(f"❌ {msg}")

def warning(msg: str):
    """Предупреждение"""
    logger.warning(f"⚠️ {msg}")

def set_debug(enabled: bool):
    """Установка режима отладки"""
    logger.setLevel(logging.DEBUG if enabled else logging.INFO)
