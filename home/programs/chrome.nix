{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (google-chrome.override {
      commandLineArgs = [
        "--ozone-platform=wayland"
        "--enable-widevine"
        "--enable-features=VaapiVideoDecoder,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
      ];
    })
  ];
}
