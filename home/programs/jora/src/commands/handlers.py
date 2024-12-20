import os
import json
import subprocess
from typing import Optional
from src.utils.logger import info

class CommandHandlers:
    """Обработчики команд"""

    @staticmethod
    def _extract_number(text: str) -> Optional[str]:
        """Извлекает номер из текста"""
        words = text.split()
        for word in words:
            if word.isdigit() and 1 <= int(word) <= 9:
                return word
        return None

    @staticmethod
    def _check_workspace_exists(workspace_num: int) -> bool:
        """Проверяет существование приложения на рабочем столе"""
        try:
            result = subprocess.run(['hyprctl', 'clients', '-j'],
                                  capture_output=True, text=True)
            clients = json.loads(result.stdout)
            return any(client.get('workspace', {}).get('id') == workspace_num
                      for client in clients)
        except:
            return False

    @staticmethod
    def safe_launch(command: str) -> str:
        """Безопасный запуск приложений с отвязкой от терминала"""
        return f"nohup {command} >/dev/null 2>&1 &"

    @staticmethod
    def handle_system_command(command: str):
        """Выполняет системную команду"""
        try:
            if any(app in command for app in ['firefox', 'zeditor', 'telegram-desktop']):
                os.system(CommandHandlers.safe_launch(command))
            else:
                os.system(command)
            info(f"✅ Команда выполнена: {command}")
        except Exception as e:
            info(f"❌ Ошибка выполнения команды: {e}")

    @classmethod
    def handle_scratchpad_app(cls, text: str, app_name: str):
        """Обработчик приложений в scratchpad"""
        workspace_num = cls._extract_number(text)

        if workspace_num:
            info(f"🚀 Перехожу на рабочий стол {workspace_num}")
            os.system(f"hyprctl dispatch workspace {workspace_num}")

        # Проверяем, нужно ли запустить приложение
        if app_name == "telegram":
            os.system(f"pgrep telegram-desktop || {cls.safe_launch('telegram-desktop')}")

        info(f"🚀 Открываю {app_name} в scratchpad")
        os.system(f"hyprctl dispatch togglespecialworkspace {app_name}")

    @classmethod
    def handle_fixed_workspace_app(cls, text: str, app_name: str,
                                 default_workspace: str, launch_command: str):
        """Обработчик приложений с фиксированным рабочим столом"""
        workspace_num = cls._extract_number(text) or default_workspace

        info(f"🚀 Перехожу на рабочий стол {workspace_num}")
        os.system(f"hyprctl dispatch workspace {workspace_num}")

        if not cls._check_workspace_exists(int(workspace_num)):
            info(f"🚀 Запускаю {app_name}")
            os.system(cls.safe_launch(launch_command))
        else:
            info(f"✨ {app_name} уже запущен")

    @classmethod
    def handle_reboot(cls, text: str):
        """Обработчик команды перезагрузки"""
        if "подтверждаю" in text.lower():
            info("🔄 Перезагружаю систему...")
            cls.handle_system_command("systemctl reboot")
        else:
            info("⚠️ Для перезагрузки системы скажи 'перезагрузи подтверждаю'")

    @staticmethod
    def handle_workspace(text: str):
        """Обработчик перехода на рабочий стол"""
        workspace_num = CommandHandlers._extract_number(text)
        if workspace_num:
            info(f"🚀 Перехожу на рабочий стол {workspace_num}")
            os.system(f"hyprctl dispatch workspace {workspace_num}")
