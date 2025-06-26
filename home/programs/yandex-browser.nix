{ pkgs, inputs, ... }:
let
  yandex-browser-wayland = pkgs.writeShellScriptBin "yandex-browser-wayland" ''
    exec ${
      inputs.yandex-browser.packages.${pkgs.system}.yandex-browser-stable
    }/bin/yandex-browser-stable \
      --ozone-platform-hint=auto
      "$@"
  '';
in
{
  home.packages = [
    inputs.yandex-browser.packages.${pkgs.system}.yandex-browser-stable
    yandex-browser-wayland
  ];

}
