{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, disko,  home-manager, ... }:
     let
       system = "x86_64-linux";
       hostName = "emerald";
     in
     {
       nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
         inherit system;
         modules = [
           ./nixos/configuration.nix
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
}
