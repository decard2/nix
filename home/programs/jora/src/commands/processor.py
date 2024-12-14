from typing import Optional, Dict, List, Callable
from src.recognition.streamer import StreamRecognizer
from src.utils.logger import info

class Command:
    """Базовый класс команды"""
    def __init__(self, keywords: List[str], handler: Callable, description: str):
        self.keywords = keywords
        self.handler = handler
        self.description = description

    def matches(self, text: str) -> bool:
        """Проверяет соответствие текста ключевым словам"""
        return any(keyword in text.lower() for keyword in self.keywords)

    def execute(self, text: str):
        """Выполняет команду"""
        self.handler(text)

class CommandProcessor:
    """Обработчик голосовых команд"""

    def __init__(self):
        self.commands: Dict[str, Command] = {}
        self.is_dictating = False
        self.stream_recognizer: Optional[StreamRecognizer] = None
        self._setup_commands()

    def _setup_commands(self):
        """Настройка базовых команд"""
        # Пока добавляем только команду диктовки
        self.add_command(
            "dictate",
            ["диктуй", "запиши", "записывай", "под диктовку", "надиктовать"],
            self._handle_dictation,
            "Запуск режима диктовки"
        )

    def _handle_dictation(self, text: str):
        """Обработчик команды диктовки"""
        info("📝 Погнали диктовать! (Скажи 'Завершить запись' для завершения)")
        if self.stream_recognizer:
            self.is_dictating = True
            info("✅ Можно диктовать!")

    def process(self, text: str) -> bool:
        """Обработка распознанного текста"""
        for command in self.commands.values():
            if command.matches(text):
                command.execute(text)
                return True
        return False

    def add_command(self, name: str, keywords: List[str], handler: Callable, description: str):
        """Добавление новой команды"""
        self.commands[name] = Command(keywords, handler, description)

    def set_stream_recognizer(self, recognizer: StreamRecognizer):
        """Установка распознавателя потока"""
        self.stream_recognizer = recognizer
