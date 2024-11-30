{pkgs, ...}: {
  imports = [
    ./kctl.nix
  ];

  home.packages = [
    (pkgs.callPackage ./yandex-cloud-cli.nix {})
  ];
}
