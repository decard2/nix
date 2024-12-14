import subprocess
import shutil
from src.utils.logger import error, debug

class DebugPlayer:
    """Класс для отладочного воспроизведения аудио"""

    @staticmethod
    def play_file(file_path: str) -> bool:
        """Воспроизводит аудио файл"""

        # Проверяем наличие play
        if not shutil.which('play'):
            error("Команда 'play' не найдена. Установите sox: nix-env -iA nixos.sox")
            return False

        try:
            debug(f"Воспроизвожу {file_path}")
            subprocess.run(['play', '-q', file_path], check=True)
            return True

        except subprocess.CalledProcessError as e:
            error(f"Ошибка воспроизведения: {e}")
            return False

        except Exception as e:
            error(f"Ошибка: {e}")
            return False
