import os
import json
import subprocess
from typing import Callable, List, Dict, Optional

class Command:
    def __init__(self, keywords: List[str], handler: Callable, description: str):
        self.keywords = keywords
        self.handler = handler
        self.description = description

    def matches(self, text: str) -> bool:
        """Проверяет, соответствует ли текст ключевым словам команды"""
        return any(keyword in text.lower() for keyword in self.keywords)

    def execute(self, text: str):
        """Выполняет команду, передавая ей исходный текст"""
        self.handler(text)

class CommandProcessor:
    def __init__(self):
        self.commands: Dict[str, Command] = {}
        self.is_dictating = False
        self.stream_recognizer = None
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
        """Настройка всех команд"""
        # Команда диктовки
        self.add_command(
            "dictate",
            ["диктуй", "запиши", "записывай", "под диктовку", "надиктовать"],
            self._handle_dictation,
            "Запуск режима диктовки"
        )

        # Команда закрытия окна
        self.add_command(
            "close",
            ["закрыть", "выключить"],
            lambda text: self._handle_system_command("hyprctl dispatch killactive"),
            "Закрыть активное окно"
        )

        self.add_command(
            "reboot",
            ["перезагрузи", "ребут", "перезагрузка", "рестарт"],
            lambda text: self._handle_reboot(text),
            "Перезагрузка системы"
        )

    def _extract_number(self, text: str) -> Optional[str]:
        """Извлекает номер из текста"""
        words = text.split()
        for word in words:
            if word.isdigit() and 1 <= int(word) <= 9:
                return word
        return None

    def _find_app_in_text(self, text: str, app_forms: List[str]) -> bool:
        """Проверяет наличие приложения в тексте с учетом склонений"""
        return any(form in text.lower() for form in app_forms)

    def _handle_reboot(self, text: str):
        """Обработчик команды перезагрузки"""
        if "подтверждаю" in text.lower():
            print("🔄 Перезагружаю систему...")
            self._handle_system_command("systemctl reboot")
        else:
            print("⚠️ Для перезагрузки системы скажи 'перезагрузи подтверждаю'")

    def _handle_system_command(self, command: str):
        """Выполняет системную команду"""
        try:
            os.system(command)
            print(f"✅ Команда выполнена: {command}")
        except Exception as e:
            print(f"❌ Ошибка выполнения команды: {e}")

    def _handle_scratchpad_app(self, text: str, app_name: str):
        """
        Обработчик приложений в scratchpad:
        1. Если есть номер - переходим на рабочий стол
        2. Открываем приложение в scratchpad
        """
        workspace_num = self._extract_number(text)

        if workspace_num:
            print(f"🚀 Перехожу на рабочий стол {workspace_num}")
            os.system(f"hyprctl dispatch workspace {workspace_num}")

        print(f"🚀 Открываю {app_name} в scratchpad")
        os.system(f"hyprctl dispatch togglespecialworkspace {app_name}")

    def _handle_fixed_workspace_app(self, text: str, app_name: str, default_workspace: str, launch_command: str):
        """
        Обработчик приложений с фиксированным рабочим столом:
        1. Определяем целевой рабочий стол (указанный или дефолтный)
        2. Проверяем наличие приложения на этом столе
        3. Переходим на стол и запускаем если нужно
        """
        workspace_num = self._extract_number(text) or default_workspace

        print(f"🚀 Перехожу на рабочий стол {workspace_num}")
        os.system(f"hyprctl dispatch workspace {workspace_num}")

        if not self._check_workspace_exists(int(workspace_num)):
            print(f"🚀 Запускаю {app_name}")
            os.system(f"{launch_command} &")
        else:
            print(f"✨ {app_name} уже запущен")

    def _check_workspace_exists(self, workspace_num: int) -> bool:
        """Проверяет существование приложения на рабочем столе"""
        try:
            result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True)
            clients = json.loads(result.stdout)
            return any(client.get('workspace', {}).get('id') == workspace_num for client in clients)
        except:
            return False

    def _handle_dictation(self, text: str):
        """Обработчик команды диктовки"""
        print("📝 Погнали диктовать! (Скажи 'Завершить запись' для завершения)")
        if self.stream_recognizer:
            self.is_dictating = True
            print("✅ Можно диктовать!")

    def process(self, text: str) -> bool:
        """Обработка текста и выполнение команд"""
        # Сначала проверяем базовые команды (диктовка, закрытие окна)
        for command in self.commands.values():
            if command.matches(text):
                command.execute(text)
                return True

        # Проверяем scratchpad приложения
        if self._find_app_in_text(text, self.word_forms["telegram"]):
            self._handle_scratchpad_app(text, "telegram")
            return True

        if self._find_app_in_text(text, self.word_forms["term"]):
            self._handle_scratchpad_app(text, "term")
            return True

        if self._find_app_in_text(text, self.word_forms["btop"]):
            self._handle_scratchpad_app(text, "btop")
            return True

        if self._find_app_in_text(text, self.word_forms["jora"]):
            self._handle_scratchpad_app(text, "jora")
            return True

        # Проверяем приложения с фиксированным рабочим столом
        if self._find_app_in_text(text, self.word_forms["editor"]):
            self._handle_fixed_workspace_app(text, "Zed", "3", "zeditor")
            return True

        if self._find_app_in_text(text, self.word_forms["browser"]):
            self._handle_fixed_workspace_app(text, "Firefox", "4", "firefox")
            return True

        # Проверяем переход на рабочий стол
        workspace_num = self._extract_number(text)
        if workspace_num:
            print(f"🚀 Перехожу на рабочий стол {workspace_num}")
            os.system(f"hyprctl dispatch workspace {workspace_num}")
            return True

        return False

    def add_command(self, name: str, keywords: List[str], handler: Callable, description: str):
        """Добавление новой команды"""
        self.commands[name] = Command(keywords, handler, description)

    def set_stream_recognizer(self, recognizer):
        """Установка stream_recognizer"""
        self.stream_recognizer = recognizer
