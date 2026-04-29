{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.yandex-browser.packages.${pkgs.stdenv.hostPlatform.system}.yandex-browser-stable
  ];
}
