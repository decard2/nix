{ ... }: {
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 = "1";
    VK_ICD_FILENAMES =
      "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
  };
}
