from typing import Callable, List, Dict

class Command:
    def __init__(self, keywords: List[str], handler: Callable, description: str):
        self.keywords = keywords
        self.handler = handler
        self.description = description

    def matches(self, text: str) -> bool:
        """Проверяет, соответствует ли текст ключевым словам команды"""
        return any(keyword in text.lower() for keyword in self.keywords)

class CommandProcessor:
    def __init__(self):
        self.commands: Dict[str, Command] = {}
        self.is_dictating = False
        self.stream_recognizer = None
        self._setup_commands()

    def _setup_commands(self):
        """Настройка базовых команд"""
        self.add_command(
            "dictate",
            ["диктуй", "запиши", "записывай", "под диктовку", "надиктовать"],
            self._handle_dictation,
            "Запуск режима диктовки"
        )

    def add_command(self, name: str, keywords: List[str], handler: Callable, description: str):
        """Добавление новой команды"""
        self.commands[name] = Command(keywords, handler, description)

    def process(self, text: str) -> bool:
        """Обработка текста и выполнение соответствующей команды"""
        for command in self.commands.values():
            if command.matches(text):
                command.handler()
                return True
        return False

    def set_stream_recognizer(self, recognizer):
        """Установка stream_recognizer"""
        self.stream_recognizer = recognizer

    def _handle_dictation(self):
        """Обработчик команды диктовки"""
        print("📝 Погнали диктовать! (Скажи 'Завершить запись' для завершения)")
        if self.stream_recognizer:

            print("✅ Можно диктовать!")
        self.is_dictating = True
