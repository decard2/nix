import os
import json
import urllib.request
from datetime import datetime, timedelta
from typing import Optional

from src.utils.logger import  error

class CommandRecognizer:
    """Распознавание коротких голосовых команд через Yandex SpeechKit REST API"""

    def __init__(self):
        self.folder_id = os.getenv("YANDEX_FOLDER_ID")
        self.oauth_token = os.getenv("YANDEX_OAUTH_TOKEN")
        self.iam_token: Optional[str] = None
        self.token_expires: Optional[datetime] = None

        if not self.folder_id or not self.oauth_token:
            error("Отсутствуют YANDEX_FOLDER_ID или YANDEX_OAUTH_TOKEN")
            raise ValueError("Не установлены переменные окружения Yandex")

        self._update_iam_token()

    def _update_iam_token(self) -> bool:
        try:
            if (self.iam_token is None or
                self.token_expires is None or
                datetime.now() >= self.token_expires):

                url = "https://iam.api.cloud.yandex.net/iam/v1/tokens"
                data = json.dumps({"yandexPassportOauthToken": self.oauth_token}).encode('utf-8')
                request = urllib.request.Request(
                    url,
                    data=data,
                    headers={'Content-Type': 'application/json'}
                )

                response = urllib.request.urlopen(request)
                decoded = json.loads(response.read().decode('utf-8'))

                self.iam_token = decoded.get('iamToken')
                self.token_expires = datetime.now() + timedelta(hours=11)
            return True

        except Exception as e:
            error(f"Ошибка получения IAM токена: {e}")
            return False

    def recognize_command(self, audio_file: str) -> Optional[str]:
        try:
            if not self._update_iam_token():
                return None

            with open(audio_file, "rb") as f:
                audio_data = f.read()

            params = "&".join([
                "topic=general",
                f"folderId={self.folder_id}",
                "lang=ru-RU"
            ])

            url = urllib.request.Request(
                f"https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?{params}",
                data=audio_data,
                headers={"Authorization": f"Bearer {self.iam_token}"}
            )

            response = urllib.request.urlopen(url).read().decode('UTF-8')
            result = json.loads(response)

            text = result.get("result", "")
            return text

        except Exception as e:
            error(f"Ошибка распознавания: {e}")
            return None
