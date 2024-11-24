
description = "Твоя офигенная система, братан!";

inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  nixos-anywhere = {
    url = "github:nix-community/nixos-anywhere";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

outputs = { self, nixpkgs, home-manager, disko, nixos-anywhere, ... }@inputs:
let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};
in
{
  nixosConfigurations = {
    emerald = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./nixos/configuration.nix
        ./nixos/disko.nix
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.decard = import ./home/home.nix;
        }
      ];
    };
  };
};
}
