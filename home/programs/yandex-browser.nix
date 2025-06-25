{ pkgs, inputs, ... }:
{
  home.packages = with inputs.yandex-browser.packages.${pkgs.system}; [
    yandex-browser-stable
  ];
}
