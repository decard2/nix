{
  systemd.user.sessionVariables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
    EDITOR = "nano";
    VISUAL = "zeditor";
    TERM = "xterm-color";
    # Для Zed
    XKB_CONFIG_ROOT = "/run/current-system/sw/share/X11/xkb";
    PATH = "$HOME/.local/bin:$PATH";
    DEEPSEEK_API_KEY = "sk-35039be1f9084afe802f95f4e8e331a7";
  };
}
