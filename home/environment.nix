{ ... }:
let
  vars = {
    EDITOR = "nano";
    VISUAL = "zeditor";
    TERM = "xterm-color";
    XKB_CONFIG_ROOT = "/run/current-system/sw/share/X11/xkb";
    PATH = "$HOME/.local/bin:$PATH";
  };
in
{
  systemd.user.sessionVariables = vars;
  home.sessionVariables = vars;
}
