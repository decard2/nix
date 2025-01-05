{ pkgs, ... }: {
  home.packages = with pkgs; [ yofi papirus-icon-theme ];

  # Конфиг для yofi
  xdg.configFile."yofi/yofi.config".text = ''
    width = 400
    height = 512
    term = "kitty"

    corner_radius = "16"
    font = "FiraCode Nerd Font"
    font_size = 24

    bg_color = 0x1E1E2Eee
    bg_border_color = 0x89B4FAff
    bg_border_width = 3.0

    [input_text]
    font_color = 0xCDD6F4ff
    bg_color = 0x313244ff
    margin = "5"
    padding = "10"

    [list_items]
    font_color = 0xCDD6F4ff
    selected_font_color = 0x89B4FAff
    match_color = 0xF5C2E7ff
    margin = "5 10"
    hide_actions = true
    action_left_margin = 60
    item_spacing = 2
    icon_spacing = 5

    [icon]
    size = 24
    theme = "Papirus"
  '';
}
