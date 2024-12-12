from typing import Callable, List, Dict
import re

class Command:
    def __init__(self, keywords: List[str], handler: Callable, description: str):
        self.keywords = keywords
        self.handler = handler
        self.description = description

    def matches(self, text: str) -> bool:
        """Проверяет, соответствует ли текст ключевым словам команды"""
        return any(re.search(rf'\b{keyword}\b', text.lower()) for keyword in self.keywords)

class CommandProcessor:
    def __init__(self):
        self.commands: Dict[str, Command] = {}
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

    def _handle_dictation(self):
        """Обработчик команды диктовки"""
        print("📝 Погнали диктовать! (Скажи 'стоп' для завершения)")
