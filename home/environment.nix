{ ... }:
let
  vars = {
    EDITOR = "nano";
    VISUAL = "zeditor";
    TERM = "xterm-color";
    XKB_CONFIG_ROOT = "/run/current-system/sw/share/X11/xkb";
    PATH = "$HOME/.local/bin:$HOME/yandex-cloud/bin:$PATH";
    GOOGLE_API_KEY = "AQ.Ab8RN6IQJGNNgpJO2quDTpg-O4mDewRUPfn4qEhOgOOq1dHQCg";
  };
in
{
  systemd.user.sessionVariables = vars;
  home.sessionVariables = vars;
}
