{ pkgs, ... }:
{
  imports = [
    ./kctl.nix
    ./s3.nix
  ];

  home.packages = [
    (pkgs.callPackage ./yandex-cloud-cli.nix { })
  ];
}
