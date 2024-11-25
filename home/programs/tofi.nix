{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    tofi
  ];

  home.file.".config/tofi/config".text = ''
    # Основные настройки
    width = 100%
    height = 150
    border-width = 0
    outline-width = 0
    padding-left = 15
    padding-top = 8
    result-spacing = 25
    num-results = 7
    font = Noto Sans
    font-size = 14

    # Позиционирование
    anchor = top
    horizontal = true

    # Цвета (максимально простые)
    background-color = #000000A0
    text-color = #FFFFFF
    selection-color = #FFFFFFCC

    # Поведение
    prompt-text = "> "
    hide-cursor = true
    ascii-input = true
  '';
}
