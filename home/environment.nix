{ pkgs, ... }:
let
  vars = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
    EDITOR = "nano";
    VISUAL = "zeditor";
    TERM = "xterm-color";
    # Для Zed
    XKB_CONFIG_ROOT = "/run/current-system/sw/share/X11/xkb";
    PATH = "$HOME/.local/bin:$PATH";
    DEEPSEEK_API_KEY = "sk-35039be1f9084afe802f95f4e8e331a7";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas";
  };
in
{
  systemd.user.sessionVariables = vars;
  home.sessionVariables = vars;
}
