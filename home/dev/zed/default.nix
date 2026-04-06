{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zed-editor
    nixd
    nixfmt
    helm-ls
  ];

  home.sessionVariables = {
    GEMINI_API_KEY = "AIzaSyBZy8bL2qP6rVIEh8vxayqxxQhg_sxYbyI";
  };

  xdg.configFile."zed/settings.json".source = ./settings.json;
}
