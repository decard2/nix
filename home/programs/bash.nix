{pkgs, ...}: {
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Базовые алиасы
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    # Настройки bash
    bashrcExtra = ''
      # История
      HISTSIZE=10000
      HISTFILESIZE=20000
      HISTCONTROL=ignoreboth

      # Цветной prompt без экранирования
      PS1='\e[01;32m\u@\h\e[00m:\e[01;34m\w\e[00m\$ '

      # Включаем цветной вывод
      alias ls='ls --color=auto'
      alias grep='grep --color=auto'

      # Исправляем автодополнение
      if [ -f /etc/profile.d/bash_completion.sh ]; then
        . /etc/profile.d/bash_completion.sh
      fi
    '';
  };

  # Добавляем зависимости для bash
  home.packages = with pkgs; [
    bash-completion
  ];
}
