{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zed-editor
    nixd
    nixfmt
    helm-ls
  ];
}
