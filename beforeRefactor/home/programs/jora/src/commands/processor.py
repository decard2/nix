from typing import Optional, Dict, List, Callable
from src.recognition.streamer import StreamRecognizer
from src.utils.logger import info
from src.commands.handlers import CommandHandlers

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

        # Словарь для склонений
        self.word_forms = {
            "telegram": ["телега", "телеграм", "telegram", "телегу", "телеги", "телеге"],
            "term": ["терминал", "консоль", "терминала", "консоли", "шел", "шелл"],
            "btop": ["процессы", "нагрузка", "процессов", "нагрузки", "монитор"],
            "editor": ["редактор", "кодер", "идэ", "редактора", "кодера"],
            "browser": ["браузер", "интернет", "браузера", "firefox", "фаерфокс"],
            "jora": ["жора", "жору", "жоры", "жоре", "помощник", "ассистент"]
        }

        self._setup_commands()

    def _setup_commands(self):
        """Настройка базовых команд"""
        # Диктовка
        self.add_command(
            "dictate",
            ["диктуй", "запиши", "записывай", "под диктовку", "надиктовать"],
            self._handle_dictation,
            "Запуск режима диктовки"
        )

        # Системные команды
        self.add_command(
            "close",
            ["закрыть", "выключить"],
            lambda text: CommandHandlers.handle_system_command(
                "hyprctl dispatch killactive"
            ),
            "Закрыть активное окно"
        )

        self.add_command(
            "reboot",
            ["перезагрузить систему", "перезагрузка системы"],
            CommandHandlers.handle_reboot,
            "Перезагрузка системы"
        )

    def _find_app_in_text(self, text: str, app_forms: List[str]) -> bool:
        """Проверяет наличие приложения в тексте с учетом склонений"""
        return any(form in text.lower() for form in app_forms)

    def _handle_dictation(self, text: str):
        """Обработчик команды диктовки"""
        info("📝 Погнали диктовать! (Скажи 'Завершить запись' для завершения)")
        if self.stream_recognizer:
            self.is_dictating = True
            info("✅ Можно диктовать!")

    def process(self, text: str) -> bool:
        """Обработка распознанного текста"""
        # Проверяем базовые команды
        for command in self.commands.values():
            if command.matches(text):
                command.execute(text)
                return True

        # Проверяем scratchpad приложения
        if self._find_app_in_text(text, self.word_forms["telegram"]):
            CommandHandlers.handle_scratchpad_app(text, "telegram")
            return True

        if self._find_app_in_text(text, self.word_forms["term"]):
            CommandHandlers.handle_scratchpad_app(text, "term")
            return True

        if self._find_app_in_text(text, self.word_forms["btop"]):
            CommandHandlers.handle_scratchpad_app(text, "btop")
            return True

        if self._find_app_in_text(text, self.word_forms["jora"]):
            CommandHandlers.handle_scratchpad_app(text, "jora")
            return True

        # Проверяем приложения с фиксированным рабочим столом
        if self._find_app_in_text(text, self.word_forms["editor"]):
            CommandHandlers.handle_fixed_workspace_app(
                text, "Zed", "3", "zeditor"
            )
            return True

        if self._find_app_in_text(text, self.word_forms["browser"]):
            CommandHandlers.handle_fixed_workspace_app(
                text, "Firefox", "4", "firefox"
            )
            return True

        # Проверяем переход на рабочий стол
        CommandHandlers.handle_workspace(text)
        return True

    def add_command(self, name: str, keywords: List[str],
                   handler: Callable, description: str):
        """Добавление новой команды"""
        self.commands[name] = Command(keywords, handler, description)

    def set_stream_recognizer(self, recognizer: StreamRecognizer):
        """Установка распознавателя потока"""
        self.stream_recognizer = recognizer
