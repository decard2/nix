{ ... }:
let
  vars = {
    EDITOR = "nano";
    VISUAL = "zeditor";
    TERM = "xterm-color";
    XKB_CONFIG_ROOT = "/run/current-system/sw/share/X11/xkb";
    PATH = "$HOME/.local/bin:$HOME/yandex-cloud/bin:$HOME/.pulumi/bin:$HOME/.opencode/bin:$HOME/.cargo/bin:$PATH";
  };
in
{
  systemd.user.sessionVariables = vars;
  home.sessionVariables = vars;
}
