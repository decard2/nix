import os
import json
import subprocess
from colors import Colors

COMMAND_SYNONYMS = {
    "телеграм": ["телега", "телеграмм", "сообщения"],
    "терминал": ["консоль", "шел"],
    "редактор": ["кодер", "идэ"],
    "браузер": ["интернет"],
    "закрыть": ["выключить"],
}

def normalize_command(text):
    text = text.lower()
    for main_word, synonyms in COMMAND_SYNONYMS.items():
        if any(syn in text for syn in synonyms):
            return text.replace(synonyms[0], main_word)
    return text

def check_workspace_exists(workspace_num):
    try:
        result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True)
        clients = json.loads(result.stdout)
        return any(client.get('workspace', {}).get('id') == workspace_num for client in clients)
    except:
        return False

def extract_number(text):
    numbers = {
        "один": "1", "два": "2", "три": "3",
        "четыре": "4", "пять": "5", "шесть": "6",
        "семь": "7", "восемь": "8", "девять": "9"
    }

    for word, num in numbers.items():
        if word in text.lower():
            return num
    return None

def type_text(text):
    subprocess.run(['wtype', text + ' '])  # Добавляем пробел после текста

def execute_command(text, dictation_mode=False):
    if dictation_mode:
        type_text(text)
        print(f"{Colors.GREEN}📝 Текст введён: '{text}'{Colors.END}")
        return

    text = normalize_command(text)
    workspace_num = extract_number(text)

    if "запись" in text.lower():
        return "DICTATION_MODE"

    if "закрыть" in text.lower():
        command = "hyprctl dispatch killactive"
        print(f"{Colors.GREEN}💀 Закрываю активное окно{Colors.END}")
        os.system(command)
        return

    # Сначала переключаемся на нужный воркспейс, если указан
    if workspace_num:
        os.system(f"hyprctl dispatch workspace {workspace_num}")

    # Telegram
    if any(word in text.lower() for word in ["телега", "телеграм", "telegram"]):
        command = "hyprctl dispatch togglespecialworkspace telegram"
        print(f"{Colors.GREEN}🚀 Открываю телегу{Colors.END}")
        os.system(command)
        return

    # Terminal
    if any(word in text.lower() for word in ["терминал", "консоль"]):
        command = "hyprctl dispatch togglespecialworkspace term"
        print(f"{Colors.GREEN}🚀 Открываю терминал{Colors.END}")
        os.system(command)
        return

    # System Monitor
    if any(word in text.lower() for word in ["процессы", "нагрузка"]):
        command = "hyprctl dispatch togglespecialworkspace btop"
        print(f"{Colors.GREEN}🚀 Открываю системный монитор{Colors.END}")
        os.system(command)
        return

    # Editor
    if "редактор" in text.lower() or "кодер" in text.lower():
        target_workspace = workspace_num if workspace_num else "3"
        os.system(f"hyprctl dispatch workspace {target_workspace}")

        if not check_workspace_exists(int(target_workspace)):
            command = "zed &"
            print(f"{Colors.GREEN}🚀 Запускаю Zed на рабочем столе {target_workspace}{Colors.END}")
            os.system(command)
        else:
            print(f"{Colors.BLUE}🔍 Zed уже открыт на рабочем столе {target_workspace}{Colors.END}")
        return

    # Browser
    if "браузер" in text:
        target_workspace = workspace_num if workspace_num else "4"
        os.system(f"hyprctl dispatch workspace {target_workspace}")

        if not check_workspace_exists(int(target_workspace)):
            command = "firefox &"
            print(f"{Colors.GREEN}🚀 Запускаю Firefox на рабочем столе {target_workspace}{Colors.END}")
            os.system(command)
        else:
            print(f"{Colors.BLUE}🔍 Браузер уже открыт на рабочем столе {target_workspace}{Colors.END}")
        return

    # Just workspace switching
    if workspace_num:
        print(f"{Colors.GREEN}🚀 Перехожу на рабочий стол {workspace_num}{Colors.END}")
        return
