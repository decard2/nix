{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
      size = 12;
    };
    settings = {
      background_opacity = "0.90";
      confirm_os_window_close = 0;
    };
    extraConfig = '''';
  };
}
