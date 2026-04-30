{
  programs.ghostty = {
    enable = true;
    settings = {
      background = "#201f22";
      background-opacity = 0.90;
      background-opacity-cells = true;
      keybind = [ "super+space=ignore" ];
      # Каждый запуск — отдельный процесс, иначе Hyprland-правила
      # `[workspace ... silent]` не срабатывают: окно создаёт основной
      # инстанс через DBus, и привязка по PID теряется.
      gtk-single-instance = false;
    };
  };
}
