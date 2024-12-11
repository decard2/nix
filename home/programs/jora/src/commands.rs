use colored::*;
use serde_json::Value;
use std::process::Command;

pub struct Commands;

impl Commands {
    pub fn normalize_command(text: &str) -> String {
        let text = text.to_lowercase();
        let synonyms = [
            (vec!["телега", "телеграмм", "сообщения"], "телеграм"),
            (vec!["консоль", "шел"], "терминал"),
            (vec!["кодер", "идэ"], "редактор"),
            (vec!["интернет"], "браузер"),
            (vec!["выключить"], "закрыть"),
        ];

        let mut normalized = text.clone();
        for (syns, main) in synonyms.iter() {
            if syns.iter().any(|s| text.contains(s)) {
                normalized = text.replace(syns[0], main);
            }
        }
        normalized
    }

    fn check_workspace_exists(workspace_num: i32) -> bool {
        let output = Command::new("hyprctl")
            .args(&["clients", "-j"])
            .output()
            .ok();

        if let Some(output) = output {
            if let Ok(clients) = serde_json::from_slice::<Value>(&output.stdout) {
                if let Some(clients) = clients.as_array() {
                    return clients.iter().any(|client| {
                        client["workspace"]["id"].as_i64() == Some(workspace_num as i64)
                    });
                }
            }
        }
        false
    }

    fn extract_number(text: &str) -> Option<String> {
        let numbers = [
            ("1", "1"),
            ("2", "2"),
            ("3", "3"),
            ("4", "4"),
            ("5", "5"),
            ("6", "6"),
            ("7", "7"),
            ("8", "8"),
            ("9", "9"),
        ];

        for (word, num) in numbers.iter() {
            if text.to_lowercase().contains(word) {
                return Some(num.to_string());
            }
        }
        None
    }

    pub fn execute_command(text: &str, dictation_mode: bool) -> Option<String> {
        if dictation_mode {
            Command::new("wtype").arg(format!("{} ", text)).spawn().ok();
            println!("{}", format!("📝 Текст введён: '{}'", text).green());
            return None;
        }

        let text = Self::normalize_command(text);
        let workspace_num = Self::extract_number(&text);

        if text.contains("запись") {
            return Some("DICTATION_MODE".to_string());
        }

        if text.contains("закрыть") {
            println!("{}", "💀 Закрываю активное окно".green());
            Command::new("hyprctl")
                .args(&["dispatch", "killactive"])
                .spawn()
                .ok();
            return None;
        }

        // Переключение на воркспейс, если указан
        if let Some(num) = &workspace_num {
            Command::new("hyprctl")
                .args(&["dispatch", "workspace", num])
                .spawn()
                .ok();
        }

        // Обработка команд для приложений
        match text {
            t if t.contains("телеграм") => {
                println!("{}", "🚀 Открываю телегу".green());
                Command::new("hyprctl")
                    .args(&["dispatch", "togglespecialworkspace", "telegram"])
                    .spawn()
                    .ok();
            }
            t if t.contains("терминал") => {
                println!("{}", "🚀 Открываю терминал".green());
                Command::new("hyprctl")
                    .args(&["dispatch", "togglespecialworkspace", "term"])
                    .spawn()
                    .ok();
            }
            t if t.contains("процессы") || t.contains("нагрузка") => {
                println!("{}", "🚀 Открываю системный монитор".green());
                Command::new("hyprctl")
                    .args(&["dispatch", "togglespecialworkspace", "btop"])
                    .spawn()
                    .ok();
            }
            t if t.contains("редактор") => {
                let target_workspace = workspace_num.unwrap_or_else(|| "3".to_string());
                if !Self::check_workspace_exists(target_workspace.parse().unwrap()) {
                    println!(
                        "{}",
                        format!("🚀 Запускаю Zed на рабочем столе {}", target_workspace).green()
                    );
                    Command::new("zed").arg("&").spawn().ok();
                } else {
                    println!(
                        "{}",
                        format!("🔍 Zed уже открыт на рабочем столе {}", target_workspace).blue()
                    );
                }
            }
            t if t.contains("браузер") => {
                let target_workspace = workspace_num.unwrap_or_else(|| "4".to_string());
                if !Self::check_workspace_exists(target_workspace.parse().unwrap()) {
                    println!(
                        "{}",
                        format!("🚀 Запускаю Firefox на рабочем столе {}", target_workspace)
                            .green()
                    );
                    Command::new("firefox").arg("&").spawn().ok();
                } else {
                    println!(
                        "{}",
                        format!(
                            "🔍 Браузер уже открыт на рабочем столе {}",
                            target_workspace
                        )
                        .blue()
                    );
                }
            }
            _ if workspace_num.is_some() => {
                println!(
                    "{}",
                    format!("🚀 Перехожу на рабочий стол {}", workspace_num.unwrap()).green()
                );
            }
            _ => {}
        }

        None
    }
}
